#!/usr/bin/env python3
"""Generate Mapbox/MapLibre glyph .pbf files for a font (e.g. Noto Sans).

This replicates the exact output of Mapbox's node-fontnik / gen-glyphs:

* Each glyph is rendered as a **raw signed-distance-field (SDF) bitmap** (NOT
  PNG) with a 3px border, using the same algorithm as fontnik's
  `sdf_glyph_foundry::RenderSDF` (outline decomposition + distance to line
  segments + winding-number inside test).
* The protobuf has the **outer `glyphs` wrapper**: `glyphs { fontstack = 1 }`,
  where each fontstack is `{ name=1, range=2, glyphs=3 }` and each glyph is
  `{ id=1, bitmap=2, width=3, height=4, left=5, top=6, advance=7 }`.

MapLibre's native parser (`glyph_pbf.cpp`) requires exactly this: it reads
`glyphs.next(1)` -> `get_message()` for the fontstack, and validates that the
bitmap size equals `(width + 2*borderSize) * (height + 2*borderSize)` with
`borderSize = 3`. A PNG-embedded or unwrapped PBF fails with
"unknown pbf field type exception" / glyphs are dropped.

Output is one `.pbf` per 256-codepoint Unicode block, named `{begin}-{end}.pbf`
(e.g. `0-255.pbf`, `256-511.pbf`) — the exact naming MapLibre requests via its
`{range}` glyph URL token.

Usage:
    python gen_glyphs.py --font <path.ttf> --output <outdir> [--name <fontstack>]
                         [--height 24] [--range-split 256] [--full]
"""

import argparse
import math
import os

import freetype
from fontTools.ttLib import TTFont

# fontnik constants (must match sdf_glyph_foundry::RenderSDF)
BUFFER = 3          # border around glyph (MapLibre Glyph::borderSize)
RADIUS = 8          # SDF radius in px
CUTOFF = 0.25       # SDF cutoff
RENDER_SIZE = 24    # fontnik renders at a fixed 24px


# ---------------------------------------------------------------------------
# Outline decomposition (replicates fontnik's agg curve flattening)
# ---------------------------------------------------------------------------

def _subdiv_quad(p0, p1, p2, out, depth=0):
    """Flatten a quadratic Bezier into line segments appended to `out`."""
    if depth >= 8:
        out.append(p2)
        return
    l2 = (p2[0] - p0[0]) ** 2 + (p2[1] - p0[1]) ** 2
    if l2 > 0:
        t = ((p1[0] - p0[0]) * (p2[0] - p0[0]) + (p1[1] - p0[1]) * (p2[1] - p0[1])) / l2
        t = max(0.0, min(1.0, t))
        proj = (p0[0] + t * (p2[0] - p0[0]), p0[1] + t * (p2[1] - p0[1]))
        dist = math.hypot(p1[0] - proj[0], p1[1] - proj[1])
        if dist < 0.5:
            out.append(p2)
            return
    a = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2)
    b = ((p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2)
    mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    _subdiv_quad(p0, a, mid, out, depth + 1)
    _subdiv_quad(mid, b, p2, out, depth + 1)


def _subdiv_cubic(p0, p1, p2, p3, out, depth=0):
    """Flatten a cubic Bezier into line segments appended to `out`."""
    if depth >= 8:
        out.append(p3)
        return
    l2 = (p3[0] - p0[0]) ** 2 + (p3[1] - p0[1]) ** 2
    if l2 > 0:
        def dist_to_chord(pt):
            t = ((pt[0] - p0[0]) * (p3[0] - p0[0]) + (pt[1] - p0[1]) * (p3[1] - p0[1])) / l2
            t = max(0.0, min(1.0, t))
            proj = (p0[0] + t * (p3[0] - p0[0]), p0[1] + t * (p3[1] - p0[1]))
            return math.hypot(pt[0] - proj[0], pt[1] - proj[1])
        if max(dist_to_chord(p1), dist_to_chord(p2)) < 0.5:
            out.append(p3)
            return
    a = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2)
    b = ((p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2)
    c = ((p2[0] + p3[0]) / 2, (p2[1] + p3[1]) / 2)
    d = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    e = ((b[0] + c[0]) / 2, (b[1] + c[1]) / 2)
    f = ((d[0] + e[0]) / 2, (d[1] + e[1]) / 2)
    _subdiv_cubic(p0, a, d, f, out, depth + 1)
    _subdiv_cubic(f, e, c, p3, out, depth + 1)


def _decompose(outline):
    """Decompose a FreeType outline into closed rings of points (px units)."""
    rings = []
    current = []

    def move_to(v, _ctx):
        nonlocal current
        if current:
            rings.append(current)
        current = [(v.x / 64.0, v.y / 64.0)]

    def line_to(v, _ctx):
        current.append((v.x / 64.0, v.y / 64.0))

    def conic_to(c, to, _ctx):
        p0 = current[-1]
        _subdiv_quad(p0, (c.x / 64.0, c.y / 64.0), (to.x / 64.0, to.y / 64.0), current)

    def cubic_to(c1, c2, to, _ctx):
        p0 = current[-1]
        _subdiv_cubic(p0, (c1.x / 64.0, c1.y / 64.0),
                      (c2.x / 64.0, c2.y / 64.0), (to.x / 64.0, to.y / 64.0), current)

    outline.decompose(move_to=move_to, line_to=line_to,
                      conic_to=conic_to, cubic_to=cubic_to)
    if current:
        rings.append(current)
    return rings


# ---------------------------------------------------------------------------
# SDF rendering (replicates fontnik's RenderSDF)
# ---------------------------------------------------------------------------

def _dist_to_segment(p, a, b):
    l2 = (b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2
    if l2 == 0:
        return math.hypot(p[0] - a[0], p[1] - a[1])
    t = ((p[0] - a[0]) * (b[0] - a[0]) + (p[1] - a[1]) * (b[1] - a[1])) / l2
    t = max(0.0, min(1.0, t))
    proj = (a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1]))
    return math.hypot(p[0] - proj[0], p[1] - proj[1])


def _min_dist_to_segments(segments, pt):
    best = float('inf')
    for a, b in segments:
        d = _dist_to_segment(pt, a, b)
        if d < best:
            best = d
    return min(best, RADIUS)


def _is_left(p0, p1, p2):
    return (p1[0] - p0[0]) * (p2[1] - p0[1]) - (p2[0] - p0[0]) * (p1[1] - p0[1])


def _point_in_rings(rings, pt):
    """Winding-number point-in-polygon test (matches fontnik PolyContainsPoint)."""
    wn = 0
    for ring in rings:
        n = len(ring)
        for i in range(n):
            x1, y1 = ring[i]
            x2, y2 = ring[(i + 1) % n]
            if y1 <= pt[1]:
                if y2 > pt[1] and _is_left((x1, y1), (x2, y2), pt) > 0:
                    wn += 1
            else:
                if y2 <= pt[1] and _is_left((x1, y1), (x2, y2), pt) < 0:
                    wn -= 1
    return wn != 0


def _render_sdf(rings, width, height):
    """Render the SDF bitmap for a glyph (raw bytes, size (w+6)*(h+6))."""
    bw = width + 2 * BUFFER
    bh = height + 2 * BUFFER
    bitmap = bytearray(bw * bh)
    radius_by_256 = 256.0 / RADIUS
    offset = 0.5

    segments = []
    for ring in rings:
        n = len(ring)
        for i in range(n):
            segments.append((ring[i], ring[(i + 1) % n]))

    for y in range(bh):
        ypos = bh - y - 1  # flip vertically (fontnik does this)
        for x in range(bw):
            pt = (x + offset, y + offset)
            d = _min_dist_to_segments(segments, pt) * radius_by_256
            if _point_in_rings(rings, pt):
                d = -d
            d += CUTOFF * 256
            n = int(max(0.0, min(255.0, d)))
            bitmap[ypos * bw + x] = 255 - n
    return bytes(bitmap)


def glyph_sdf(face, codepoint):
    """Render one codepoint as a fontnik-compatible SDF glyph.

    Returns (bitmap_or_None, width, height, left, top, advance).
    """
    face.load_char(codepoint, freetype.FT_LOAD_NO_HINTING | freetype.FT_LOAD_NO_BITMAP)
    slot = face.glyph
    adv = round(slot.advance.x / 64)  # 26.6 fixed-point -> px

    if slot.format != freetype.FT_GLYPH_FORMAT_OUTLINE:
        return None, 0, 0, 0, 0, adv

    rings = _decompose(slot.outline)
    if not rings:
        return None, 0, 0, 0, 0, adv

    xs = [p[0] for ring in rings for p in ring]
    ys = [p[1] for ring in rings for p in ring]
    xmin, xmax = math.floor(min(xs)), math.ceil(max(xs))
    ymin, ymax = math.floor(min(ys)), math.ceil(max(ys))

    width = xmax - xmin
    height = ymax - ymin
    if width == 0 or height == 0:
        return None, 0, 0, 0, 0, adv

    rings = [[(px - xmin + BUFFER, py - ymin + BUFFER) for (px, py) in ring]
             for ring in rings]

    bitmap = _render_sdf(rings, width, height)
    return bitmap, width, height, xmin, ymax, adv


# ---------------------------------------------------------------------------
# Protobuf encoding (mirrors fontstack.proto with the outer `glyphs` wrapper)
# ---------------------------------------------------------------------------

def _varint(n):
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def _tag(field, wire):
    return _varint((field << 3) | wire)


def _ldelim(field, payload):
    return _tag(field, 2) + _varint(len(payload)) + payload


def _uint32(field, val):
    return _tag(field, 0) + _varint(val)


def _sint32(field, val):
    # Zigzag encoding: 0->0, -1->1, 1->2, -2->3, 2->4, ...
    z = (val << 1) ^ (val >> 31)
    return _tag(field, 0) + _varint(z)


def _encode_fontstack(name, range_str, glyphs):
    """glyphs: list of (id, bitmap_or_None, w, h, left, top, advance)."""
    fs = bytearray()
    fs += _ldelim(1, name.encode('utf-8'))          # fontstack.name
    fs += _ldelim(2, range_str.encode('utf-8'))     # fontstack.range "0-255"

    for (gid, bitmap, w, h, left, top, advance) in glyphs:
        g = bytearray()
        g += _uint32(1, gid)                        # glyph.id
        if bitmap:
            g += _ldelim(2, bitmap)                 # glyph.bitmap (raw SDF)
        g += _uint32(3, w)                          # glyph.width
        g += _uint32(4, h)                          # glyph.height
        g += _sint32(5, left)                       # glyph.left
        g += _sint32(6, top)                        # glyph.top
        g += _uint32(7, advance)                    # glyph.advance
        fs += _ldelim(3, bytes(g))

    # Outer `glyphs` message: field 1 = repeated fontstack.
    return _ldelim(1, bytes(fs))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description='Generate Mapbox/MapLibre glyph PBFs')
    ap.add_argument('--font', required=True, help='Input TTF/OTF font file')
    ap.add_argument('--output', required=True, help='Output directory for .pbf files')
    ap.add_argument('--name', default=None,
                    help='Fontstack name (default: derived from font filename)')
    ap.add_argument('--height', type=int, default=24,
                    help='Render size in px (fontnik default 24; larger = crisper)')
    ap.add_argument('--range-split', type=int, default=256,
                    help='Codepoints per range block (default 256)')
    ap.add_argument('--full', action='store_true',
                    help='Emit all Unicodes incl. supplementary planes')
    ap.add_argument('--skew', type=float, default=0.0,
                    help='Skew angle in degrees (positive=lean right, '
                         'negative=lean left/backslant). Default 0.')
    ap.add_argument('--min', type=int, default=0)
    ap.add_argument('--max', type=int, default=0x10FFFF)
    args = ap.parse_args()

    font = TTFont(args.font, fontNumber=0)
    upm = font['head'].unitsPerEm
    cmap = font.getBestCmap() or font.getCharacterMap()

    name = args.name or os.path.splitext(os.path.basename(args.font))[0]
    os.makedirs(args.output, exist_ok=True)

    cps = {c for c in cmap.keys() if args.min <= c <= args.max}
    if not args.full:
        cps = {c for c in cps if c <= 0xFFFF}

    split = args.range_split
    ranges = {}
    for cp in cps:
        block = cp - (cp % split)
        ranges.setdefault(block, []).append(cp)

    face = freetype.Face(args.font)
    face.set_char_size(args.height * 64)
    if args.skew:
        tan = math.tan(math.radians(args.skew))
        # Horizontal shear: x' = x + tan*y ; y' = y
        # freetype.Matrix is (xx, xy, yx, yy) in 16.16 fixed point with
        #   x' = xx*x + yx*y
        #   y' = xy*x + yy*y
        # So the shear goes in the yx slot (x depends on y).
        matrix = freetype.Matrix(0x10000, 0, int(tan * 0x10000), 0x10000)
        face.set_transform(matrix, freetype.Vector(0, 0))

    total_glyphs = 0
    written = 0
    for block in sorted(ranges.keys()):
        glyphs_here = []
        for cp in sorted(ranges[block]):
            try:
                bitmap, w, h, left, top, adv = glyph_sdf(face, cp)
            except Exception:
                continue
            glyphs_here.append((cp, bitmap, w, h, left, top, adv))
            total_glyphs += 1
        if not glyphs_here:
            continue
        range_str = f"{block}-{block + split - 1}"
        pbf = _encode_fontstack(name, range_str, glyphs_here)
        fname = os.path.join(args.output, f"{range_str}.pbf")
        with open(fname, 'wb') as f:
            f.write(pbf)
        written += 1

    font.close()
    print(f"Wrote {written} .pbf files, {total_glyphs} glyphs to {args.output} "
          f"(fontstack '{name}', upm {upm}, height {args.height}px)")


if __name__ == '__main__':
    main()
