"""world_style_lint.py : world modules take colours only from WorldStyle (s1-plan §3a/§4). Exit 1 on any colour literal.
Banned: Color3.fromRGB / Color3.new / Color3.fromHSV / Color3.fromHex, BrickColor, '#RRGGBB' literals. One converter line
tagged `-- WorldStyle rgb helper` per file is allowed (it maps WorldStyle triples to Color3)."""
import pathlib, re, sys
ROOT = pathlib.Path(__file__).resolve().parents[1]
FILES = [  # (path, enabled) : TycoonWorld joined at S3, HomeCommons at S5
 ('mountain/world/WorldKit.luau', True),
 ('mountain/shared/WorldPill.luau', True),
 ('mountain/server/TycoonWorld.luau', True),
 ('mountain/client/WorldPills.client.luau', True),
 ('mountain/client/WorldFx.client.luau', True),
 ('mountain/world/HomeCommons.luau', False),
]
BAN = re.compile(r'Color3\s*\.\s*(fromRGB|new|fromHSV|fromHex)\b|BrickColor|#[0-9A-Fa-f]{6}\b')
TAG = '-- WorldStyle rgb helper'
bad = 0; checked = 0
for rel, on in FILES:
    if not on: continue
    f = ROOT / rel
    if not f.exists(): print(f'FAIL missing {rel}'); bad += 1; continue
    checked += 1; helpers = 0
    for n, line in enumerate(f.read_text(encoding='utf-8').splitlines(), 1):
        if TAG in line:
            helpers += 1
            if helpers > 1 or BAN.sub('', line.split('--')[0]).count('Color3') : print(f'FAIL {rel}:{n} extra helper'); bad += 1
            continue
        if BAN.search(line): print(f'FAIL {rel}:{n} {line.strip()[:80]}'); bad += 1
print(f'world_style_lint: {checked} file(s), {bad} violation(s)')
sys.exit(1 if bad else 0)
