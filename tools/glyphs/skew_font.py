#!/usr/bin/env python3
"""Skew (shear) a font's glyph outlines to synthesize a backslant variant.

Applies x' = x + tan(angle) * y to every glyph's outline (FreeType font
units, y up). Positive angle -> right-lean (forward italic), negative angle
-> left-lean (backslant).

Usage:
    python skew_font.py --font in.ttf --angle -12.02 --output out.ttf
"""
import argparse
import math

from fontTools.ttLib import TTFont
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen


def skew_font(in_path, out_path, angle_deg):
    font = TTFont(in_path)
    shear_x = math.tan(math.radians(angle_deg))
    glyph_set = font.getGlyphSet()

    for glyph_name in font.getGlyphOrder():
        if glyph_name == '.notdef':
            continue
        ttpen = TTGlyphPen(glyph_set)
        skew_pen = TransformPen(ttpen, (1.0, shear_x, 0.0, 1.0, 0.0, 0.0))
        try:
            glyph_set[glyph_name].draw(skew_pen)
        except Exception:
            continue
        font['glyf'][glyph_name] = ttpen.glyph()

    font.save(out_path)
    print(f'Wrote skewed font: {out_path} (angle {angle_deg} deg, shear {shear_x:.4f})')


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--font', required=True)
    ap.add_argument('--output', required=True)
    ap.add_argument('--angle', required=True, type=float,
                    help='Shear angle in degrees (positive=right-lean)')
    args = ap.parse_args()
    skew_font(args.font, args.output, args.angle)