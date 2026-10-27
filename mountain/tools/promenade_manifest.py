"""Write the runtime-source sync manifest for the promenade review Studio session."""
import json
from package_free_climb import PREFIXES, ROOT
rows = []
for folder, prefix in PREFIXES.items():
    for path in sorted((ROOT / 'mountain' / folder).rglob('*.luau')):
        rel = path.relative_to(ROOT / 'mountain' / folder)
        parent = '.'.join([prefix, *rel.parts[:-1]])
        name = path.name.split('.')[0]
        cls = 'Script' if path.name.endswith('.server.luau') else 'LocalScript' if path.name.endswith('.client.luau') else 'ModuleScript'
        rows.append([parent, name, cls, path.relative_to(ROOT).as_posix()])
out = ROOT / 'evidence/homebase_promenade_2026-10-26/sync-manifest.json'
out.write_text(json.dumps(rows, indent=1))
print(len(rows), 'sources')
