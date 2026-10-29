"""Acceptance checks for structure, provenance, source-backed bridges, and vault diff."""
import hashlib
import json
import re
import zipfile
from pathlib import Path

from refresh import EXPORT, OUT, ROOT, VAULT, WORK, read, vault_files


def main():
    project, vault, merged = (read(p) for p in (OUT / 'graph.json', WORK / 'out/graph.json', WORK / 'merged-graph.json'))
    ids = {n['id'] for n in merged['nodes']}
    edges = merged['links']
    assert len(merged['nodes']) == len(project['nodes']) + len(vault['nodes'])
    cross = [e for e in edges if e['source'].split('::')[0] != e['target'].split('::')[0]]
    assert len(edges) == len(project['links']) + len(vault['links']) + len(cross)
    assert all(e['source'] in ids and e['target'] in ids for e in edges)
    assert all(e.get('provenance') and e.get('reason') and e.get('confidence_score') for e in cross)
    index = (EXPORT / 'Graph Index.md').read_text(encoding='utf-8')
    stamps = re.findall(r'exports/([^/]+)/Graph Index', index)
    assert len(stamps) == 1
    folder = EXPORT / 'exports' / stamps[0]
    canvas = read(folder / 'Graph Map.canvas')
    hubs = list(folder.glob('Hub *.md'))
    communities = {(n.get('repo'), n.get('community'), n.get('community_name')) for n in merged['nodes']}
    assert len(hubs) == len(communities) == len(canvas['nodes'])
    assert all((VAULT / n['file']).is_file() for n in canvas['nodes'])
    by_id = {n['id']: n for n in merged['nodes']}
    cases = [
        ('vault_decisions_server_authoritative_claims', 'src/core/server/Claims.luau', 'function Claims.tryClaim'),
        ('vault_open_questions_verify_real_datastore', 'src/core/server/Store.luau', 'DataStore'),
        ('vault_open_questions_verify_real_datastore', 'design/expedition-persistence-home.md', 'DataStore'),
        ('vault_open_questions_day_night_clock', 'src/core/server/Clock.luau', 'Clock'),
        ('vault_decisions_graphify_refresh', 'design/graphify-refresh-2026-10-22.md', 'Graphify'),
    ]
    checked = []
    for vault_id, target_path, source_text in cases:
        matches = [e for e in cross if e['source'] == 'vault::' + vault_id and
                   by_id[e['target']].get('source_file') == target_path]
        if vault_id == 'vault_decisions_graphify_refresh':
            matches = [e for e in cross if e['source'].startswith('vault::') and
                       by_id[e['source']].get('source_file') == 'src/Climb & Collect/Decisions.md' and
                       by_id[e['target']].get('source_file') == target_path]
        assert matches, (vault_id, target_path)
        assert source_text.lower() in (ROOT / target_path).read_text(encoding='utf-8-sig').lower()
        checked.append(f'{vault_id} -> {target_path}')
    quality = read(OUT / 'quality.json')
    assert quality['coverage']['missing_project_files'] == []
    assert quality['coverage']['missing_vault_notes'] == []
    assert quality['graph']['broken_edges'] == 0 and quality['graph']['weak_community_ids'] == []
    assert read(OUT / 'query-benchmark.json')['recall_at_8'] == 1
    backups = sorted((Path.home() / 'Documents').glob('vault-backup-graphify-2026-10-22-204958.zip'))
    assert len(backups) == 1
    before = {}
    with zipfile.ZipFile(backups[0]) as z:
        for sf in vault_files():
            before[sf] = hashlib.sha256(z.read(sf)).hexdigest()
    modified = sorted(sf for sf, path in vault_files().items()
                      if hashlib.sha256(path.read_bytes()).hexdigest() != before[sf])
    assert modified == ['Climb & Collect/Climb & Collect.md', 'Climb & Collect/Milestones.md'], modified
    print(json.dumps({'project': len(project['nodes']), 'vault': len(vault['nodes']),
                      'merged': len(merged['nodes']), 'cross_links': len(cross),
                      'hubs': len(hubs), 'canvas_nodes': len(canvas['nodes']),
                      'source_backed_bridges': checked, 'modified_source_notes': modified}, indent=2))


if __name__ == '__main__':
    main()
