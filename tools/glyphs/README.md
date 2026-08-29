# Glyph generation (MapLibre / Mapbox glyph PBFs)

This folder contains the tooling and output for generating **glyph `.pbf` files**
that MapLibre GL renders text from. The map's `style.json` references fonts via
the `glyphs` URL template:

```json
"glyphs": "https://<your-server>/glyphs/{fontstack}/{range}.pbf"
```

MapLibre requests `{fontstack}/{range}.pbf`, where `{fontstack}` is the value of
`text-font` in a symbol layer and `{range}` is the **`{begin}-{end}`** codepoint
span of a 256-glyph block (e.g. `0-255`, `256-511`, `512-767`, ...).

## Fonts used

The map needs these fontstacks (matching the `text-font` values in `style.json`):

| Fontstack (`text-font`) | Noto Sans source file    | Role                                                           |
| ----------------------- | ------------------------ | -------------------------------------------------------------- |
| `Noto Sans`             | `NotoSans-Regular.ttf`   | Regular upright (settlements, selitteet, road names, water)    |
| `Noto Sans Bold`        | `NotoSans-Bold.ttf`      | Bold (municipalities `nimisto_kunnat`)                         |
| `Noto Sans Italic`      | `NotoSans-Italic.ttf`    | Italic / forward-slant, leans RIGHT (terrain `nimisto_maasto`) |
| `Noto Sans Italic Left` | `NotoSans-Backslant.ttf` | Backslant, leans LEFT (water names)                            |

> **Backslant**: `NotoSans-Backslant.ttf` is synthesized from `NotoSans-Regular.ttf`
> by shearing its outlines `x' = x + tan(-12.02°)·y` (see `skew_font.py`), so the
> water-name glyphs lean LEFT, opposite to the terrain italic which leans RIGHT.
>
> **Shear axis (fixed 2026-08-27)**: The shear must be **horizontal** — the top
> of each letter shifts left/right while the bottom stays put. In
> `skew_font.py` the `TransformPen` matrix is `(1.0, 0.0, shear_x, 1.0, 0.0, 0.0)`
> (shear in the `yx` slot: `x' = x + shear_x·y`). The old code put the shear in
> the `xy` slot (`y' = y + shear_x·x`), which sheared vertically and made the
> right side lower than the left. The same fix was applied to the `--skew`
> option in `gen_glyphs.py` (`freetype.Matrix(0x10000, 0, tan*0x10000, 0x10000)`).

## Generated output

`assets/static/glyphs/<fontstack>/<begin>-<end>.pbf` — one file per Unicode
block that the font actually contains glyphs for. **All Unicode ranges present in
the font are emitted** (BMP), so Finnish/Swedish diacritics (ÅÄÖ, ŠŽ, etc.) and
any other script render correctly. The `{begin}-{end}` filename matches exactly
what MapLibre requests via its `glyphs` URL token.

- `Noto Sans/` — 28 files, 3006 glyphs
- `Noto Sans Bold/` — 28 files, 3006 glyphs
- `Noto Sans Italic/` — 27 files, 3003 glyphs
- `Noto Sans Italic Left/` — 28 files, 3006 glyphs

## Regenerating

```bash
# set up deps (once)
python3 -m venv .venv
.venv/bin/pip install fonttools freetype-py

# 1) synthesize the backslant font (leans LEFT) from the upright Regular
.venv/bin/python tools/glyphs/skew_font.py \
  --font assets/static/NotoSans-Regular.ttf \
  --output assets/static/NotoSans-Backslant.ttf --angle -12.02

# 2) generate each fontstack (BMP-only; fast ~26s each)
.venv/bin/python tools/glyphs/gen_glyphs.py \
  --font assets/static/NotoSans-Regular.ttf \
  --output "assets/static/glyphs/Noto Sans" \
  --name "Noto Sans" --height 24

# ... repeat for Bold / Italic / Italic Left (see table above)
#     Italic Left uses --font assets/static/NotoSans-Backslant.ttf
```

Options:

- `--height 24` — render size in px (fontnik default 24; larger = crisper but bigger files)
- `--full` — also emit supplementary-plane ranges (fontnik/Mapbox are BMP-only; not needed for this map)
- `--range-split 256` — codepoints per block (MapLibre default 256)

> **Format (fixed 2026-08-27)**: `gen_glyphs.py` replicates Mapbox's
> `node-fontnik` exactly: each glyph is a **raw SDF bitmap** (NOT PNG) with a
> 3px border, and the protobuf has the **outer `glyphs` wrapper**
> (`glyphs { fontstack = 1 }`). MapLibre's native parser (`glyph_pbf.cpp`)
> requires this exact structure — a PNG-embedded or unwrapped PBF fails with
> "unknown pbf field type exception" and no text renders.

> **Metrics (fixed 2026-08-27)**: FreeType's `slot.advance.x` is in 26.6
> fixed-point (1/64 px); MapLibre expects pixels, so the generator divides by 64. The `sint32` zigzag encoding for `left`/`top` was also corrected (the old
> negative branch corrupted metrics). Without these, glyphs render with wrong
> spacing/offsets or not at all.

## Validating

```bash
.venv/bin/python tools/glyphs/validate_glyphs.py assets/static/glyphs/*/*.pbf
```

## Serving

Upload the contents of `assets/static/glyphs/` to your server so that:

```
https://<your-server>/glyphs/Noto Sans/0-255.pbf
https://<your-server>/glyphs/Noto Sans/256-511.pbf
...
```

Then point `style.json`'s `glyphs` URL at it. Note the fontstack name contains
spaces — the URL must be URL-encoded (`Liberation%20Sans%20NLSFI`) or the server
must accept spaces in paths.

## How it works

`gen_glyphs.py` renders each glyph as a **signed-distance-field (SDF)** bitmap
using FreeType's `FT_RENDER_MODE_SDF` (the same technique as Mapbox's
`gen-glyphs` / `node-fontnik`), embeds it as a grayscale PNG, and packs it into
the Mapbox `fontstack.proto` protobuf format. The schema is in `glyphs.proto`.
