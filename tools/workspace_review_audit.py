"""Read-only audit of the two October 25 review branches and saved artifacts."""
from pathlib import Path
import hashlib
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
HUD = Path.home() / 'Documents/ClimbCollect-HUD-2026-10-25'
TYCOON = Path.home() / 'Documents/Codex/2026-10-24/referenced-chatgpt-conversation-this-is-an-4/work/climb-collect'
RECOVERY = Path.home() / 'Documents/ClimbCollect-HUD-Recovery-2026-10-25/ClimbCollect.HUD.Complete.Review02.rbxlx'


def inspect(path, source):
    data = path.read_bytes()
    doc = ET.fromstring(data)
    scripts = {}
    services = {}
    def walk(node, prefix=''):
        for child in node.findall('Item'):
            props = child.find('Properties')
            label = props.find("*[@name='Name']").text
            address = prefix + '/' + label
            code = props.find("*[@name='Source']")
            if code is not None:
                scripts[address] = (code.text or '').replace('\r\n', '\n')
            walk(child, address)
    walk(doc)
    for child in doc.findall('Item'):
        label = child.find("Properties/*[@name='Name']").text
        services[label] = hashlib.sha256(ET.tostring(child)).hexdigest()
    matches, mismatches = [], []
    for folder, prefix in [('shared','/ReplicatedStorage/MountainShared'), ('server','/ServerScriptService/MountainServer'), ('client','/StarterPlayer/StarterPlayerScripts/MountainClient')]:
        for file in (source/'mountain'/folder).rglob('*.luau'):
            rel = file.relative_to(source/'mountain'/folder)
            name = rel.stem.removesuffix('.client').removesuffix('.server')
            key = prefix + '/' + '/'.join((*rel.parts[:-1], name))
            expected = file.read_text(encoding='utf-8-sig')
            (matches if scripts.get(key) == expected else mismatches).append(key)
    return {'path':str(path), 'bytes':len(data), 'sha256':hashlib.sha256(data).hexdigest(), 'runtime_matches':len(matches), 'runtime_mismatches':mismatches, 'services':services}, scripts


def main():
    current, current_scripts = inspect(HUD/'outputs/ClimbCollect.HUD.Complete.Review02.rbxlx', HUD)
    recovery, recovery_scripts = inspect(RECOVERY, HUD)
    tycoon, _ = inspect(TYCOON.parent.parent/'outputs/ClimbCollect.Tycoon.Review06.rbxlx', TYCOON)
    diffs = []
    for file in (HUD/'mountain').rglob('*.luau'):
        rel = file.relative_to(HUD)
        other = TYCOON/rel
        if other.exists() and file.read_text(encoding='utf-8-sig') != other.read_text(encoding='utf-8-sig'):
            diffs.append(str(rel))
    report = {'date':'2026-10-25', 'scope':'Read-only disk/source audit; no fresh playtest', 'hud_current':current, 'hud_recovery':recovery, 'tycoon':tycoon, 'normalized_source_differences':sorted(diffs), 'hud_changed_script_paths':sorted(k for k in set(current_scripts)|set(recovery_scripts) if current_scripts.get(k)!=recovery_scripts.get(k)), 'hud_changed_services':sorted(k for k in set(current['services'])|set(recovery['services']) if current['services'].get(k)!=recovery['services'].get(k))}
    output = ROOT/'evidence/workspace_review_2026-10-25'
    output.mkdir(parents=True, exist_ok=True)
    (output/'artifact-audit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k not in ('hud_current','hud_recovery','tycoon')},indent=2))
    for label, entry in [('hud_current',current),('hud_recovery',recovery),('tycoon',tycoon)]:
        print(label, entry['sha256'], 'matches',entry['runtime_matches'],'mismatches',entry['runtime_mismatches'])


if __name__ == '__main__':
    main()
