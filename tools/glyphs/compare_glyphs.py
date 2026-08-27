#!/usr/bin/env python3
"""Compare glyph bitmaps between two fontstack folders."""
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


def fields(b):
    i = 0
    out = []
    while i < len(b):
        tag, i = varint(b, i)
        f = tag >> 3
        w = tag & 7
        if w == 0:
            v, i = varint(b, i)
            out.append((f, w, v))
        elif w == 2:
            ln, i = varint(b, i)
            out.append((f, w, b[i:i + ln]))
            i += ln
        else:
            raise Exception('wire ' + str(w))
    return out


def get_glyph(folder, cp):
    block = cp - (cp % 256)
    data = open(f'{folder}/{block}.pbf', 'rb').read()
    for g in [v for f, w, v in fields(data) if f == 3]:
        gf = fields(g)
        gid = [v for f, w, v in gf if f == 1][0]
        if gid == cp:
            return [v for f, w, v in gf if f == 2][0]
    return None


def main():
    a, b = sys.argv[1], sys.argv[2]
    cps = [65, 66, 0xE4, 0xE5, 0xF6, 0x53, 0x5A]  # A B ä å ö S Z
    same = 0
    diff = 0
    for cp in cps:
        ga = get_glyph(a, cp)
        gb = get_glyph(b, cp)
        if ga == gb:
            same += 1
            print(f'U+{cp:04X}: identical')
        else:
            diff += 1
            print(f'U+{cp:04X}: DIFFERENT')
    print(f'\nidentical={same} different={diff}')


if __name__ == '__main__':
    main()