"""Generate Unicode data, not Pharo source, from a pinned PCRE2 checkout.

Install the output in PCRE2UnicodeData using Pharo MCP. No C code or test
fixtures are embedded. Range lists contain inclusive, sorted pairs.
"""
import argparse
import collections
import json
import re
import subprocess
from pathlib import Path


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
            if not extra:
                properties['bool:' + normalized(prop)].append(interval(code))
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
            'equivalents': equivalents, 'scriptMasks': masks, 'digitSets': digits}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pcre2', type=Path, required=True)
    parser.add_argument('--revision', default='pcre2-10.49')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.write_text(json.dumps(generate(args.pcre2, args.revision),
                                     separators=(',', ':'), sort_keys=True))
