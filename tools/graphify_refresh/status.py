"""Read-only freshness and consistency check for the curated graph workflow."""
import json
import re
import sys
from pathlib import Path

from refresh import OUT, VAULT, WORK, EXPORT, file_state, source_files, vault_files


def load(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def main():
    deep = '--deep' in sys.argv[1:]
    required = [OUT / 'graph.json', OUT / 'manifest.json', WORK / 'out/graph.json',
                WORK / 'vault-manifest.json', WORK / 'merged-graph.json',
                Path.home() / '.graphify/global-graph.json', EXPORT / 'Graph Index.md']
    missing = [str(p) for p in required if not p.is_file()]
    if missing:
        print('Missing:', *missing, sep='\n  ')
        return 2
    manifest, files = load(OUT / 'manifest.json'), source_files()
    state = file_state(files, manifest, deep=deep)
    changed = [sf for sf in files if manifest.get(sf, {}).get('sha256') != state[sf]['sha256']]
    removed = sorted(set(manifest) - set(files))
    new = sorted(set(files) - set(manifest))
    vm, vf = load(WORK / 'vault-manifest.json'), vault_files()
    vault_state = file_state(vf, vm, deep=deep)
    vault_changed = [sf for sf in vf if vm.get(sf, {}).get('sha256') != vault_state[sf]['sha256']]
    vault_removed = sorted(set(vm) - set(vf))
    project, vault, merged, global_graph = (load(p) for p in (required[0], required[2], required[4], required[5]))
    active = required[-1].read_text(encoding='utf-8-sig')
    matches = re.findall(r'graphify/exports/([^/]+)/Graph Index', active)
    export_dir = EXPORT / 'exports' / matches[-1] if matches else None
    issues = []
    if not export_dir or not (export_dir / 'Graph Index.md').is_file():
        issues.append('active versioned index missing')
    else:
        index = (export_dir / 'Graph Index.md').read_text(encoding='utf-8-sig')
        canvas_path = export_dir / 'Graph Map.canvas'
        try:
            canvas = load(canvas_path)
            if len(canvas['nodes']) != len(list(export_dir.glob('Hub *.md'))):
                issues.append('canvas/hub count differs')
            if not all((VAULT / n['file']).is_file() for n in canvas['nodes']):
                issues.append('canvas references missing hubs')
        except (OSError, ValueError, KeyError):
            issues.append('canvas does not parse')
        hubs = len(list(export_dir.glob('Hub *.md')))
        communities = len({(n.get('repo'), n.get('community'), n.get('community_name')) for n in merged['nodes']})
        if hubs != communities or index.count(']] (') != hubs:
            issues.append('not every community is indexed')
        if f'Merged: {len(merged["nodes"])} nodes / {len(merged["links"])} edges' not in index:
            issues.append('index counts differ from merge')
        if f'Project: {len(project["nodes"])} nodes' not in index or f'Vault: {len(vault["nodes"])} nodes' not in index:
            issues.append('index input counts differ')
        if (export_dir / 'Graph Index.md').stat().st_mtime < (WORK / 'merged-graph.json').stat().st_mtime - 1:
            issues.append('index older than merge')
    cross = sum(e['source'].split('::')[0] != e['target'].split('::')[0] for e in merged['links'])
    if export_dir and (export_dir / 'Graph Index.md').is_file() and f'cross-graph links: {cross}' not in index:
        issues.append('index cross-link count differs')
    if len(merged['nodes']) != len(project['nodes']) + len(vault['nodes']):
        issues.append('merged node count differs from project plus vault')
    if len(global_graph['nodes']) != len(merged['nodes']):
        issues.append('global node count differs from merge')
    global_ids = {n['id'] for n in global_graph['nodes']}
    for tag, graph in (('climb-collect-project', project), ('climb-collect-vault', vault)):
        if any(n['id'] not in global_ids and f"{tag}::{n['id']}" not in global_ids for n in graph['nodes']):
            issues.append(f'global registration missing {tag} nodes')
    if len(merged['links']) != len(project['links']) + len(vault['links']) + cross:
        issues.append('merged edge count differs from inputs plus cross-links')
    ids = {n['id'] for n in merged['nodes']}
    if any(e['source'] not in ids or e['target'] not in ids for e in merged['links']):
        issues.append('merged graph has dangling links')
    if any(e['source'].split('::')[0] != e['target'].split('::')[0] and not e.get('provenance') for e in merged['links']):
        issues.append('cross-graph link lacks provenance')
    if len(active.split('Current export:')) != 2:
        issues.append('active index must contain one current export pointer')
    quality_path = OUT / 'quality.json'
    if not quality_path.is_file():
        issues.append('quality report missing')
    else:
        quality = load(quality_path)
        if quality['coverage']['missing_project_files'] or quality['coverage']['missing_vault_notes']:
            issues.append('quality report shows missing input coverage')
        if quality['graph']['broken_edges'] or quality['graph']['weak_community_ids']:
            issues.append('quality report shows structural defects')
    benchmark_path = OUT / 'query-benchmark.json'
    if not benchmark_path.is_file():
        issues.append('query benchmark missing')
    elif load(benchmark_path).get('recall_at_8') != 1:
        issues.append('query benchmark regression')
    print(f'Project: {len(project["nodes"])} nodes / {len(project["links"])} edges')
    print(f'Vault: {len(vault["nodes"])} nodes / {len(vault["links"])} edges')
    print(f'Merged: {len(merged["nodes"])} nodes / {len(merged["links"])} edges / {cross} cross links')
    print(f'Global: {len(global_graph["nodes"])} nodes / {len(global_graph["links"])} edges')
    print(f'Input drift: changed={len(changed)} new={len(new)} removed={len(removed)} vault-changed={len(vault_changed)} vault-removed={len(vault_removed)}')
    for item in (changed + new + removed + vault_changed + vault_removed)[:15]:
        print('  ', item)
    for issue in issues:
        print('ISSUE:', issue)
    stale = bool(changed or new or removed or vault_changed or vault_removed or issues)
    print('Status: STALE' if stale else 'Status: CURRENT for all intended inputs')
    return 1 if stale else 0


if __name__ == '__main__':
    sys.exit(main())
