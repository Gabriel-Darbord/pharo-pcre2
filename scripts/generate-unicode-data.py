"""Generate Unicode data, not Pharo source, from a pinned PCRE2 checkout.

Writes the data as JSON, and as the two packed forms the Pharo backend carries:
the sections below as LEB128 varints, gzipped, then base64. Install each string
using Pharo MCP:

- the properties Pharo has no table for (scripts, script extensions, bidi
  classes, binary properties, grapheme breaks and the script run masks) in
  PCRE2UnicodeProperties class>>encoded;
- the general categories, case folds and decimal digits that Pharo 15 and later
  read from their own Unicode class in PCRE2PackedUnicodeTables class>>encoded.

The decode: method of each class reads its sections in the order they are
written here. No C code or test fixtures are embedded. Range lists contain
inclusive, sorted pairs.
"""
import argparse
import base64
import collections
import gzip
import json
import re
import subprocess
from pathlib import Path


def varint(value, out):
    """Append value to out as LEB128, low 7 bits first, high bit for more."""
    while True:
        part = value & 0x7F
        value >>= 7
        out.append(part | 0x80 if value else part)
        if not value:
            return


def text_section(lines, out):
    body = '\n'.join(lines).encode('utf8')
    varint(len(body), out)
    out += body


def range_section(flat, out):
    """Inclusive pairs as (gap since the last end, length), both varints."""
    varint(len(flat) // 2, out)
    previous = 0
    for index in range(0, len(flat), 2):
        start, end = flat[index], flat[index + 1]
        varint(start - previous, out)
        varint(end - start, out)
        previous = end


def code_table(table, out):
    """Codes in ascending order as gaps, each followed by its value."""
    varint(len(table), out)
    previous = 0
    for code in sorted(table):
        varint(code - previous, out)
        varint(table[code], out)
        previous = code


def triple_section(triples, out):
    """(first, last, value) runs as the gap since the last end, the length and the value."""
    varint(len(triples), out)
    previous = 0
    for first, last, value in triples:
        varint(first - previous, out)
        varint(last - first, out)
        varint(value, out)
        previous = last


def encode(out):
    return base64.b64encode(gzip.compress(bytes(out), 9)).decode('ascii')


def pack_properties(data):
    out = bytearray()
    text_section([data['version']], out)
    names = sorted(name for name in data['properties'] if not name.startswith('gc:'))
    text_section(names, out)
    for name in names:
        range_section(data['properties'][name], out)
    text_section(['%s=%s' % pair for pair in sorted(data['aliases'].items())
                  if not pair[0].startswith('gc:')], out)
    text_section(sorted(data['allowedProperties']), out)
    masks = data['scriptMasks']
    triple_section(list(zip(masks[::3], masks[1::3], masks[2::3])), out)
    return encode(out)


def pack_tables(data):
    out = bytearray()
    text_section([data['version']], out)
    categories = sorted(name[3:] for name in data['properties']
                        if name.startswith('gc:') and len(name) == 5
                        and name not in ('gc:lc', 'gc:cn'))
    text_section(categories, out)
    runs = []
    for index, category in enumerate(categories):
        ranges = data['properties']['gc:' + category]
        runs.extend((first, last, index) for first, last in zip(ranges[::2], ranges[1::2]))
    triple_section(sorted(runs), out)
    code_table({int(code): folded for code, folded in data['folds'].items()}, out)
    # A digit is stored as its value, which is never above 9.
    code_table({int(code): int(code) - zero for code, zero in data['digitSets'].items()}, out)
    return encode(out)


def normalized(name):
    return re.sub(r"[\s_-]", "", name).lower()


def merge(ranges):
    result = []
    for low, high in sorted(ranges):
        if result and low <= result[-1][1] + 1:
            result[-1][1] = max(result[-1][1], high)
        else:
            result.append([low, high])
    return result


def generate(checkout, revision):
    def read(name):
        return subprocess.check_output(
            ['git', 'show', f'{revision}:maint/Unicode.tables/{name}.txt'],
            cwd=checkout, text=True)

    def rows(name):
        for line in read(name).splitlines():
            line = line.split('#')[0].strip()
            if line:
                yield [field.strip() for field in line.split(';')]

    def interval(text):
        ends = [int(value, 16) for value in text.split('..')]
        return ends[0], ends[-1]

    catalog = subprocess.check_output(
        ['git', 'show', f'{revision}:src/pcre2_ucptables_inc.h'],
        cwd=checkout, text=True)
    allowed = {}
    for definition in re.findall(r'^#define STRING_\w+0 (.+)$', catalog, re.M):
        tokens = re.findall(r'STR_(\w+)', definition)
        name = ''.join('&' if token == 'AMPERSAND' else token for token in tokens)
        allowed[name] = True
    assert 'lu' in allowed and 'letter' not in allowed and 'l&' in allowed
    assert 'DerivedGeneralCategory-17.0.0' in read('DerivedGeneralCategory')

    properties = collections.defaultdict(list)
    aliases = {}
    for code, category, *_ in rows('DerivedGeneralCategory'):
        pair = interval(code)
        properties['gc:' + normalized(category)].append(pair)
        properties['gc:' + category[0].lower()].append(pair)
        if category in ('Lu', 'Ll', 'Lt'):
            properties['gc:lc'].append(pair)

    script_aliases = {}
    for row in rows('PropertyValueAliases'):
        family, short, *names = row
        if family in ('gc', 'sc', 'bc'):
            for name in [short, *names]:
                aliases[family + ':' + normalized(name)] = normalized(short)
                if family == 'sc':
                    script_aliases[normalized(name)] = normalized(short)

    extensions = [(interval(code), names.split())
                  for code, names, *_ in rows('ScriptExtensions')]
    extension_spans = merge([span for span, _ in extensions])
    for code, script, *_ in rows('Scripts'):
        low, high = interval(code)
        script = script_aliases[normalized(script)]
        properties['sc:' + script].append((low, high))
        cursor = low
        for first, last in extension_spans:
            if last < cursor:
                continue
            if first > high:
                break
            if cursor < first:
                properties['scx:' + script].append((cursor, first - 1))
            cursor = max(cursor, last + 1)
        if cursor <= high:
            properties['scx:' + script].append((cursor, high))
    for span, scripts in extensions:
        for script in scripts:
            properties['scx:' + script_aliases[normalized(script)]].append(span)

    known_scripts = merge([span for key, ranges in properties.items()
                           if key.startswith('sc:') for span in ranges])
    cursor = 0
    for first, last in known_scripts + [[0x110000, 0x110000]]:
        if cursor < first:
            properties['sc:zzzz'].append((cursor, first - 1))
            properties['scx:zzzz'].append((cursor, first - 1))
        cursor = last + 1

    bidi = ['l'] * 0x110000
    for span, name in re.findall(r'@missing:\s*([0-9A-F.]+);\s*(\w+)',
                                 read('DerivedBidiClass')):
        first, last = interval(span)
        value = aliases.get('bc:' + normalized(name), normalized(name))
        bidi[first:last + 1] = [value] * (last - first + 1)
    for span, name, *_ in rows('DerivedBidiClass'):
        first, last = interval(span)
        bidi[first:last + 1] = [normalized(name)] * (last - first + 1)
    start = 0
    for end in range(1, len(bidi) + 1):
        if end == len(bidi) or bidi[end] != bidi[start]:
            properties['bc:' + bidi[start]].append((start, end - 1))
            start = end
    for code, prop, *_ in rows('GraphemeBreakProperty'):
        properties['gcb:' + normalized(prop)].append(interval(code))

    for source in ('PropList', 'DerivedCoreProperties', 'emoji-data'):
        for code, prop, *extra in rows(source):
            if not extra or (prop == 'InCB' and extra[0] != 'None'):
                properties['bool:' + normalized(prop)].append(interval(code))
    for row in rows('UnicodeData'):
        if row[9] == 'Y':
            code = int(row[0], 16)
            properties['bool:bidimirrored'].append((code, code))
    for row in rows('PropertyAliases'):
        target = next(('bool:' + normalized(name) for name in row
                       if 'bool:' + normalized(name) in properties), None)
        if target:
            for name in row:
                aliases['bool:' + normalized(name)] = target[5:]

    folds = {}
    for code, status, mapping, *_ in rows('CaseFolding'):
        if status in ('C', 'S'):
            folds[int(code, 16)] = int(mapping, 16)
    classes = collections.defaultdict(set)
    for code, folded in folds.items():
        classes[folded].update((code, folded))
    equivalents = {str(code): sorted(group)
                   for group in classes.values() for code in group}
    properties = {name: [end for pair in merge(ranges) for end in pair]
                  for name, ranges in properties.items()}
    scripts = sorted(name[4:] for name in properties if name.startswith('scx:'))
    bits = {name: 1 << index for index, name in enumerate(scripts)}
    events = collections.defaultdict(int)
    for name, bit in bits.items():
        ranges = properties['scx:' + name]
        for first, last in zip(ranges[::2], ranges[1::2]):
            events[first] ^= bit
            events[last + 1] ^= bit
    masks = []
    mask = 0
    positions = sorted(events)
    all_bits = (1 << (len(bits) + 3)) - 1
    for index, first in enumerate(positions[:-1]):
        mask ^= events[first]
        compatible = mask
        for combo_index, combo in enumerate((('hani', 'hira', 'kana'),
                                             ('hani', 'bopo'),
                                             ('hani', 'hang'))):
            if any(mask & bits[name] for name in combo):
                compatible |= 1 << (len(bits) + combo_index)
        if mask & bits['zzzz']:
            compatible = 0
        if mask in (bits['zyyy'], bits['zinh']):
            compatible = all_bits
        masks.extend((first, positions[index + 1] - 1, compatible))
    digits = {str(int(row[0], 16)): int(row[0], 16) - int(row[6])
              for row in rows('UnicodeData') if row[6]}
    assert properties['gc:lu'] and equivalents['8490'] == [75, 107, 8490]
    return {'version': '17.0.0', 'properties': properties,
            'aliases': aliases, 'folds': {str(k): v for k, v in folds.items()},
            'equivalents': equivalents, 'scriptMasks': masks, 'digitSets': digits,
            'allowedProperties': allowed}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pcre2', type=Path, required=True)
    parser.add_argument('--revision', default='pcre2-10.49')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--packed-properties', type=Path,
                        help='where to write the base64 string for PCRE2UnicodeProperties')
    parser.add_argument('--packed-tables', type=Path,
                        help='where to write the base64 string for PCRE2PackedUnicodeTables')
    args = parser.parse_args()
    data = generate(args.pcre2, args.revision)
    args.output.write_text(json.dumps(data, separators=(',', ':'), sort_keys=True))
    if args.packed_properties:
        args.packed_properties.write_text(pack_properties(data))
    if args.packed_tables:
        args.packed_tables.write_text(pack_tables(data))
