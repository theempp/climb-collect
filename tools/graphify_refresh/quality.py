"""Deterministic, source-grounded graph checks. Findings are review prompts, not edits to notes."""
import json
import re
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

from refresh import OUT, ROOT, VAULT, WORK, write


def audit(project, vault, merged, files, vault_files, state, vault_state, changed):
    nodes = {n['id']: n for n in merged['nodes']}
    covered = {n.get('source_file') for n in project['nodes']}
    vault_covered = {n.get('source_file', '').removeprefix('src/') for n in vault['nodes']}
    broken = [e for e in merged['links'] if e.get('source') not in nodes or e.get('target') not in nodes]
    labels = json.loads((OUT / '.graphify_labels.json').read_text(encoding='utf-8'))
    weak = sorted({str(n.get('community')) for n in project['nodes']
                   if not n.get('community_name') or str(n.get('community')) not in labels or
                   n.get('community_name') != labels.get(str(n.get('community')))})
    by_file = defaultdict(list)
    for n in project['nodes']:
        by_file[n.get('source_file')].append(n)
    parser_gaps = []
    supplemented = Counter(n.get('source_file') for n in project['nodes'] if n.get('_origin') == 'verified_declaration')
    source_only = []
    for sf, path in files.items():
        if not sf.endswith('.luau'):
            continue
        count = sum(n.get('file_type') == 'code' for n in by_file[sf])
        if count == 0:
            parser_gaps.append({'path': sf, 'reason': 'No code symbols; source summary available'})
    for sf in files:
        if sf.endswith(('.luau', '.py')) and not any(n.get('file_type') == 'code' for n in by_file[sf]):
            source_only.append(sf)
    # A changed note that cites an older implementation date is a review candidate.
    # We do not infer that a design statement is false merely because source changed.
    outdated = []
    for sf in changed:
        if sf not in files or not sf.endswith('.md'):
            continue
        body = files[sf].read_text(encoding='utf-8-sig', errors='replace')
        dates = re.findall(r'20\d\d-\d\d-\d\d', body)
        if dates and max(dates) < datetime.fromtimestamp(state[sf]['mtime']).date().isoformat():
            outdated.append({'path': sf, 'reason': 'Changed note has no same-day dated claim; review if status is time-sensitive'})
    for sf, path in vault_files.items():
        body = path.read_text(encoding='utf-8-sig', errors='replace')
        dated_statuses = re.findall(r'^##\s+(?:Current\s+)?Status\s*\((20\d\d-\d\d-\d\d)\)', body, re.I | re.M)
        if dated_statuses and max(dated_statuses) < datetime.now().date().isoformat():
            outdated.append({'path': sf, 'reason': f'Latest status heading dated {max(dated_statuses)}; compare with current source before updating'})
    ambiguous = []
    broken_source_links = []
    for sf, path in {**files, **{'vault:' + k: v for k, v in vault_files.items()}}.items():
        if path.suffix != '.md':
            continue
        body = path.read_text(encoding='utf-8-sig', errors='replace')
        for target in re.findall(r'\]\(([^)]+)\)', body):
            target = target.split('#', 1)[0].strip('<>')
            if not target or re.match(r'^[a-z]+:', target, re.I) or re.match(r'^[A-Za-z]:[\\/]', target):
                continue
            if target.endswith('.md') and not (path.parent / target).is_file():
                broken_source_links.append({'path': sf, 'target': target})
        if sf.startswith('vault:'):
            for target in re.findall(r'\[\[([^\]|#]+)', body):
                if not (VAULT / (target + '.md')).is_file() and not (path.parent / (target + '.md')).is_file():
                    broken_source_links.append({'path': sf, 'target': target})
    by_name = defaultdict(set)
    for sf in files:
        if sf.endswith('.md'):
            by_name[Path(sf).name.lower()].add(sf)
    for sf, path in vault_files.items():
        body = path.read_text(encoding='utf-8-sig', errors='replace').lower()
        for name, paths in by_name.items():
            if len(paths) > 1 and name in body:
                ambiguous.append({'vault_path': sf, 'basename': name, 'candidates': sorted(paths)})
    semantic = [e for e in merged['links'] if e['source'].split('::')[0] != e['target'].split('::')[0]]
    no_provenance = sum(not e.get('provenance') for e in semantic)
    data = {
        'generated_at': datetime.now().astimezone().isoformat(timespec='seconds'),
        'input_changes': sorted(changed),
        'coverage': {'intended_project_files': len(files), 'indexed_project_files': len(set(files) & covered),
                     'missing_project_files': sorted(set(files) - covered),
                     'intended_vault_notes': len(vault_files), 'indexed_vault_notes': len(set(vault_files) & vault_covered),
                     'missing_vault_notes': sorted(set(vault_files) - vault_covered),
                     'code_only_summary_files': source_only,
                     'verified_declaration_supplements': dict(supplemented)},
        'graph': {'project_nodes': len(project['nodes']), 'vault_nodes': len(vault['nodes']),
                  'merged_nodes': len(merged['nodes']), 'merged_edges': len(merged['links']),
                  'cross_links': len(semantic), 'cross_links_without_provenance': no_provenance,
                  'broken_edges': len(broken), 'weak_community_ids': weak},
        'review': {'ambiguous_document_mentions': ambiguous[:100], 'possibly_outdated_changed_notes': outdated,
                   'broken_source_links': broken_source_links[:100]},
        'exclusions': ['DRS Rush', 'vault Home.md (read as instructions, not indexed)', '*.rbxl', '*.rbxlx', 'references/', 'images and video',
                       'generated Obsidian exports', 'creatures non-Python files'],
    }
    write(OUT / 'quality.json', data)
    lines = ['# Graph quality', '', f"Generated {data['generated_at']}.", '',
             f"- Indexed project inputs: {data['coverage']['indexed_project_files']}/{len(files)}",
             f"- Indexed vault notes: {data['coverage']['indexed_vault_notes']}/{len(vault_files)}",
             f"- Cross-links: {len(semantic)}; without provenance: {no_provenance}",
             f"- Broken edges: {len(broken)}; weak community labels: {len(weak)}",
             f"- Luau files with no symbols: {len(parser_gaps)}",
             f"- Source-only code files: {len(source_only)}; supplemented declarations: {sum(supplemented.values())}",
             f"- Ambiguous document mentions for review: {len(ambiguous)}", '',
             f"- Unresolved Markdown/wiki links for review: {len(broken_source_links)}", '',
             '## Review candidates', '']
    lines += [f"- `{x['path']}`: {x['reason']}" for x in (parser_gaps + outdated)[:50]]
    (OUT / 'QUALITY_REPORT.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    return data
