#!/usr/bin/env python3
"""Checks docs/protokol-siniri.md against the protocol boundary code (both directions).

Command::Kind / Status, IDeviceProvider methods and signals, the fields of every struct in DeviceTypes.h and
the parameter keys of ParameterKeys.h must appear in the document, and the document must not name anything the
code lacks. Run: python tools/check_protocol_doc.py [project root]. Exit 0 = match.
"""
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
read = lambda p: (root / p).read_text(encoding="utf-8")
doc = read("docs/protokol-siniri.md")
errors = []
sys.stdout.reconfigure(encoding="utf-8")


def section(text, title, level):
    """Body of the heading `title` (heading level `level`) up to the next heading of the same or higher level."""
    mark = "#" * level + " "
    m = re.search(r"^" + re.escape(mark + title) + r"[^\n]*\n", text, re.M)
    if not m:
        errors.append(f"belgede bölüm yok: {mark}{title}")
        return ""
    rest = text[m.end():]
    end = re.search(r"^#{1,%d} " % level, rest, re.M)
    return rest[:end.start()] if end else rest


def names(text, pattern):
    return set(re.findall(pattern, text, re.M))


def rows(text):  # first cell of every table row: | `name` | ...
    return names(text, r"^\| `([^`]+)`")


def heads(text):  # ### `Name`
    return names(text, r"^### `([^`]+)`")


def compare(what, code, written):
    for n in sorted(code - written):
        errors.append(f"{what}: kodda var, belgede yok: {n}")
    for n in sorted(written - code):
        errors.append(f"{what}: belgede var, kodda yok: {n}")


def enum_names(text, header):
    m = re.search(header + r"\s*\{(.*?)\n\s*\};", text, re.S)
    body = re.sub(r"//[^\n]*", "", m.group(1))
    return set(re.findall(r"\b([A-Z]\w*)\b\s*(?:=[^,]*)?(?:,|$)", body, re.M))


# Commands and statuses
cmd_h = read("device/api/DeviceCommand.h")
compare("Command::Kind", enum_names(cmd_h, r"enum Kind"), heads(section(doc, "Komutlar", 2)))
compare("Command::Status", enum_names(cmd_h, r"enum Status"), rows(section(doc, "Sonuç durumları", 3)))

# Provider interface
prov_h = read("device/api/IDeviceProvider.h")
code = names(prov_h, r"virtual \w[\w:<> ]*?\b(\w+)\(") | names(prov_h, r"^\s+void (\w+)\(quint64")
compare("IDeviceProvider", code, rows(section(doc, "IDeviceProvider", 3)))

# Data structs: every struct of DeviceTypes.h is a ### section of "Okunan veri yapıları"
types_h = read("device/api/DeviceTypes.h")
structs = {}
for m in re.finditer(r"^struct (\w+)\s*\{(.*?)^\};", types_h, re.S | re.M):
    body = m.group(2)
    props = names(body, r"Q_PROPERTY\([^()]*?\b(\w+) MEMBER")
    if not props:  # plain struct: members at 4 spaces of indent
        for line in re.sub(r"//.*", "", body).splitlines():
            mm = re.match(r"    (?!friend|static|enum|using|return)[\w:<>]+ (\w+)\s*(?:=[^;(]*)?;", line)
            if mm and "(" not in line:
                props.add(mm.group(1))
    structs[m.group(1)] = props
data = section(doc, "Okunan veri yapıları", 2)
compare("veri yapıları", set(structs), heads(data))
for name, fields in structs.items():
    compare(f"{name} alanları", fields, rows(section(data, name.join(["`", "`"]), 3)))

# Parameter keys
keys_h = read("device/api/ParameterKeys.h")
base = names(keys_h, r'\{"(\w+)", ParameterType')
code = {f"{{pan,tilt}}.{b}" for b in base}
code |= names(keys_h, r'QStringLiteral\("(\w+\.\w+)"\)')
zones = re.search(r'zone : \{([^}]*)\}', keys_h).group(1)
code |= {f"heater.{z}DutyPct" for z in re.findall(r'"(\w+)"', zones)}
compare("parametre anahtarları", code, rows(section(doc, "Parametre anahtarları", 2)))

for e in errors:
    print("HATA:", e)
print("protokol belgesi koda uyuyor" if not errors else f"{len(errors)} uyumsuzluk")
sys.exit(1 if errors else 0)
