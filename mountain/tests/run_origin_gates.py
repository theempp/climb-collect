"""Grep gates for Robux origin (T8, D8): production code never assigns origin='robux', and creatures are
inserted only at the four producer lines. Production = every .luau under mountain/ except mountain/tests/."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
checks = 0
def check(value, message):
    global checks
    assert value, message
    checks += 1

files = [f for f in (ROOT / 'mountain').rglob('*.luau') if 'tests' not in f.relative_to(ROOT / 'mountain').parts]
check(len(files) > 50, 'production sources found')
robux = re.compile(r"""origin\s*=(?!=)\s*(?:if\b[^\n]*?)?['"]robux['"]|\[\s*['"]origin['"]\s*\]\s*=(?!=)""")
insert = re.compile(r'table\.insert\(\s*\w+\.creatures\b')
index = re.compile(r'\.creatures\s*\[[^\]]*\]\s*=(?!=)')
grants, inserts, indexed = [], [], []
for f in files:
    rel = f.relative_to(ROOT).as_posix()
    for n, line in enumerate(f.read_text(encoding='utf-8').splitlines(), 1):
        if robux.search(line): grants.append(f'{rel}:{n}')
        if insert.search(line): inserts.append((rel, line.strip()))
        if index.search(line): indexed.append(f'{rel}:{n}')
check(not grants, f'no production origin=robux assignment: {grants}')
check(not indexed, f'no indexed creature writes: {indexed}')
where = sorted(rel for rel, _ in inserts)
check(where == ['mountain/shared/Rules.luau'] * 3 + ['mountain/shared/RunRules.luau'], f'creatures inserted only at the four producers: {inserts}')
producers = [line for _, line in inserts]
check(sum("{'mossbun','petalyn','fernox'}" in l for l in producers) == 1, 'producer: starters (nil)')
check(sum('species=g.id' in l for l in producers) == 1, 'producer: schema-1 Trial (nil)')
check(sum('species=e.species' in l and 'origin=e.origin' in l for l in producers) == 1, 'producer: hatch copies the egg origin')
check(sum('species=r.species' in l and 'origin' not in l for l in producers) == 1, 'producer: secure (nil)')
print(f'PASS {checks} origin grep gates')
