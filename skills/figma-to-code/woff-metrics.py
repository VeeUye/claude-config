"""Extract vertical metrics (unitsPerEm, ascent, descent, capHeight, xHeight)
from WOFF v1 font files using only stdlib (struct + zlib)."""
import struct
import sys
import zlib


def read_table(data, entries, tag):
    entry = entries.get(tag)
    if entry is None:
        return None
    offset, comp_length, orig_length = entry
    raw = data[offset:offset + comp_length]
    if comp_length < orig_length:
        return zlib.decompress(raw)
    return raw


def parse(path):
    with open(path, 'rb') as handle:
        data = handle.read()

    signature, flavor, length, num_tables = struct.unpack('>4sIIH', data[:14])
    assert signature == b'wOFF', f'{path}: not a WOFF v1 file'

    entries = {}
    cursor = 44
    for _ in range(num_tables):
        tag, offset, comp_length, orig_length, _checksum = struct.unpack(
            '>4sIIII', data[cursor:cursor + 20])
        entries[tag.decode('latin-1')] = (offset, comp_length, orig_length)
        cursor += 20

    head = read_table(data, entries, 'head')
    units_per_em = struct.unpack('>H', head[18:20])[0]

    hhea = read_table(data, entries, 'hhea')
    hhea_ascent, hhea_descent, hhea_line_gap = struct.unpack('>hhh', hhea[4:10])

    os2 = read_table(data, entries, 'OS/2')
    os2_version = struct.unpack('>H', os2[0:2])[0]
    typo_ascender, typo_descender, typo_line_gap = struct.unpack('>hhh', os2[68:74])
    win_ascent, win_descent = struct.unpack('>HH', os2[74:78])
    x_height = cap_height = None
    if os2_version >= 2:
        x_height, cap_height = struct.unpack('>hh', os2[86:90])

    print(f'{path}')
    print(f'  unitsPerEm     {units_per_em}')
    print(f'  hhea asc/desc/gap   {hhea_ascent} / {hhea_descent} / {hhea_line_gap}')
    print(f'  OS/2 v{os2_version} typo asc/desc/gap {typo_ascender} / {typo_descender} / {typo_line_gap}')
    print(f'  OS/2 win asc/desc   {win_ascent} / {win_descent}')
    print(f'  capHeight      {cap_height}   xHeight {x_height}')
    ratio = lambda value: round(value / units_per_em, 4)
    print(f'  ratios: hheaAsc {ratio(hhea_ascent)}  hheaDesc {ratio(hhea_descent)}'
          f'  cap {ratio(cap_height) if cap_height else "?"}  x {ratio(x_height) if x_height else "?"}')
    print()


for font_path in sys.argv[1:]:
    parse(font_path)
