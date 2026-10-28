"""Check pasted [CC-SAVE] server log lines against hosted test A.
Usage: python check_cc_save.py log.txt  (paste Developer Console Server output into log.txt)"""
import re, sys
pat = re.compile(r'\[CC-SAVE\]\s+(load|save)\s+(OK|FAIL)\s+(\d+)(.*)')
last = {}; fails = []; issues = []
for n, line in enumerate(open(sys.argv[1], encoding='utf-8', errors='replace'), 1):
	m = pat.search(line)
	if not m: continue
	kind, status, uid, rest = m.groups()
	coins = re.search(r'coins\s+(-?\d+)', rest); cr = re.search(r'creatures\s+(\d+)', rest)
	vals = (coins and int(coins[1]), cr and int(cr[1]))
	print(f'{n:>4} {kind} {status} {uid} coins={vals[0]} creatures={vals[1]}{rest if status == "FAIL" else ""}')
	if status == 'FAIL': fails.append(line.strip())
	if kind == 'load' and status == 'OK' and uid in last and last[uid] != vals:
		issues.append(f'line {n}: {uid} loaded {vals}, last save was {last[uid]}')
	if kind == 'save' and status == 'OK': last[uid] = vals
print('\nFAIL lines:', len(fails)); [print('  ' + f) for f in fails]
print('Load/save mismatches:', len(issues)); [print('  ' + i) for i in issues]
print('PASS' if not fails and not issues else 'CHECK ABOVE')
