"""Fills unfinished Turkish translations from a JSON dictionary and drops vanished entries.

Usage (project root, after `cmake --build build/cli-debug --target update_translations`):
    python tools/fill_ts.py new_texts.json
new_texts.json: {"English source": "Türkçe çeviri", ...}. Every unfinished source must be in it, otherwise
nothing is written. Sources containing XML entities (&amp; &lt; ...) are matched as they appear in the .ts file.
"""
import json
import re
import sys

TS = 'translations/IDS_GIMBAL_tr.ts'

tr = json.load(open(sys.argv[1], encoding='utf-8'))
s = open(TS, encoding='utf-8').read()
missing = []


def fill(m):
    src = m.group(1)
    if src not in tr:
        missing.append(src)
        return m.group(0)
    return f'<source>{src}</source>\n        <translation>{tr[src]}</translation>'


s, filled = re.subn(r'<source>([^<]*)</source>\n        <translation type="unfinished">[^<]*</translation>', fill, s)
if missing:
    sys.exit('no translation for:\n  ' + '\n  '.join(missing))
s, vanished = re.subn(r'\n    <message>\n        <source>[^<]*</source>\n'
                      r'        <translation type="vanished">[^<]*</translation>\n    </message>', '', s)
open(TS, 'w', encoding='utf-8', newline='\n').write(s)
print('filled', filled, 'removed vanished', vanished)
