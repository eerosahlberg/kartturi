#!/usr/bin/env python3
"""Validate generated glyph .pbf files against MapLibre's parser rules.

Checks the outer `glyphs` wrapper, the fontstack name/range, and that every
glyph passes the same validation MapLibre's `glyph_pbf.cpp` applies:
  - has id, width, height, left, top, advance
  - width/height < 256, -128 <= left/top < 128, advance < 256
  - bitmap size == (width + 2*borderSize) * (height + 2*borderSize), borderSize=3
"""
import glob
import sys


def varint(b, i):
    r = 0
    s = 0
    while True:
        x = b[i]
        i += 1
        r |= (x & 0x7F) << s
        if not x & 0x80:
            return r, i
        s += 7


def parse_msg(b):
    i = 0
    out = {}
    while i < len(b):
        tag, i = varint(b, i)
        f = tag >> 3
        w = tag & 7
        if w == 0:
            v, i = varint(b, i)
            out.setdefault(f, []).append(('varint', v))
        elif w == 2:
            ln, i = varint(b, i)
            out.setdefault(f, []).append(('bytes', b[i:i + ln]))
            i += ln
        else:
            break
    return out


def zz(v):
    return (v >> 1) ^ -(v & 1)


BORDER = 3  # MapLibre Glyph::borderSize


def main(path):
    data = open(path, 'rb').read()
    top = parse_msg(data)

    # Expect outer `glyphs` wrapper: field 1 = fontstack message.
    if 1 not in top:
        print(f'{path}: NO outer glyphs wrapper (field 1)')
        return 1
    inner = top[1][0][1]
    im = parse_msg(inner)

    name = im.get(1, [('bytes', b'')])[0][1].decode('utf-8', 'replace')
    range_str = im.get(2, [('bytes', b'')])[0][1].decode('utf-8', 'replace')
    glyphs = [v[1] for v in im.get(3, [])]

    bad = 0
    for g in glyphs:
        gm = parse_msg(g)
        if 1 not in gm:
            bad += 1
            continue
        gid = gm[1][0][1]
        w = gm[3][0][1] if 3 in gm else None
        h = gm[4][0][1] if 4 in gm else None
        left = zz(gm[5][0][1]) if 5 in gm else None
        top = zz(gm[6][0][1]) if 6 in gm else None
        adv = gm[7][0][1] if 7 in gm else None
        bmp = gm[2][0][1] if 2 in gm else None

        if None in (w, h, left, top, adv):
            bad += 1
            if bad <= 5:
                print(f'  glyph {gid}: missing field')
            continue
        if w >= 256 or h >= 256 or not (-128 <= left < 128) or not (-128 <= top < 128) or adv >= 256:
            bad += 1
            if bad <= 5:
                print(f'  glyph {gid}: out of range w={w} h={h} left={left} top={top} adv={adv}')
            continue
        if bmp is not None and len(bmp) != (w + main.border) * (h + main.border):
            bad += 1
            if bad <= 5:
                print(f'  glyph {gid}: bitmap {len(bmp)} != (w+6)*(h+6)={(w+6)*(h+6)}')
            continue

    print(f'{path}: fontstack="{name}" range={range_str} glyphs={len(glyphs)} bad={bad}')
    return bad


main.border = 6


if __name__ == '__main__':
    total = 0
    files = []
    for p in sys.argv[1:]:
        files += glob.glob(p)
    for p in sorted(files):
        total += main(p)
    print('TOTAL BAD:', total)
