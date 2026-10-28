# run_world_sounds.py : World.build must set SoundId on existing ambient Sounds too (stale ids otherwise survive a rebuild).
import pathlib, re, sys
src = (pathlib.Path(__file__).resolve().parents[1] / 'world' / 'World.luau').read_text(encoding='utf-8')
loop = re.search(r"for name,id in pairs\(\{(.*?)\}\) do\n(.*?)\n end", src, re.S)
ok = 0
def check(cond, msg):
	global ok
	if not cond: print('FAIL ' + msg); sys.exit(1)
	ok += 1
check(loop is not None, 'ambient sound loop found')
ids = dict(re.findall(r"\[?'?([\w ()]+?)'?\]?='(\d+)'", loop.group(1)))
check(ids.get('WaterfallLoop') == '9120550423', 'WaterfallLoop id')
check(ids.get('LavaLoop') == '9112823563', 'LavaLoop id')
body = loop.group(2).splitlines()
create = [l for l in body if 'if not sound then' in l]
check(len(create) == 1 and 'SoundId' not in create[0], 'SoundId not only in the creation branch')
check(any(l.strip().startswith("sound.SoundId='rbxassetid://'..id") for l in body), 'SoundId set unconditionally')
print('world sounds %d/%d checks pass' % (ok, ok))
