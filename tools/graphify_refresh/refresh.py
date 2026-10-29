"""Safely refresh the curated Climb & Collect project/vault graphs and versioned export.

Run from any directory: python tools/graphify_refresh/refresh.py
Only source and Markdown are read; existing vault exports are never replaced.
"""
import hashlib
import json
import re
import shutil
import subprocess
import sys
import zipfile
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

from graphify.extract import extract

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'graphify-out'
VAULT = Path.home() / 'Documents/Obsidian Vault'
WORK = Path.home() / 'Documents/graphify-vault-out'
EXPORT = VAULT / 'Climb & Collect/graphify'
MEMORY = Path.home() / '.claude/projects/C--Users-HOME--Desktop-climb-collect/memory'
STAMP = datetime.now().strftime('%Y-%m-%d-%H%M%S')


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def write(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def file_state(files, previous, deep=False):
    """Stat first; hash only new or metadata-changed inputs."""
    state = {}
    for sf, path in files.items():
        stat = path.stat()
        prior = previous.get(sf, {})
        sha = (prior.get('sha256') if not deep and prior.get('size') == stat.st_size and
               prior.get('mtime_ns') == stat.st_mtime_ns else None)
        state[sf] = {'sha256': sha or digest(path), 'size': stat.st_size,
                     'mtime': stat.st_mtime, 'mtime_ns': stat.st_mtime_ns}
    return state


def source_files():
    files = []
    for base in ('src', 'src_legacy_v2', 'tools'):
        files.extend(p for p in (ROOT / base).rglob('*') if p.is_file() and p.suffix in ('.luau', '.py') and '__pycache__' not in p.parts)
    files.extend(p for p in (ROOT / 'creatures').rglob('*.py') if p.is_file())
    files.extend(ROOT / name for name in ('.graphifyignore', 'AGENTS.md', 'CLAUDE.md', 'master.md', 'OVERNIGHT_BRIEF.md') if (ROOT / name).exists())
    files.append(ROOT / 'tools/graphify_refresh/verified-corrections.json')
    for base in ('design', 'evidence'):
        files.extend(p for p in (ROOT / base).rglob('*.md') if p.name != 'graphify-vault-merge-prompt.md' and not any(x in p.parts for x in ('node_modules', '.tools', 'build', 'out')))
    if MEMORY.exists():
        files.extend(MEMORY.glob('*.md'))
    return {key(p): p for p in files}


def key(path):
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return '@memory/' + path.name


def slug(value):
    return re.sub(r'[^a-z0-9]+', '_', value.lower()).strip('_')[:90]


def note_nodes(path, sf, prefix, bullets=False):
    lines = path.read_text(encoding='utf-8-sig', errors='replace').splitlines()
    title = next((re.sub(r'^#+\s*', '', line).strip() for line in lines if line.startswith('# ')), path.stem)
    stem = slug(sf)
    root_id = prefix + stem
    nodes = [dict(id=root_id, label=title, norm_label=title.lower(), file_type='document', source_file=sf,
                  source_location='L1', description=f'{title}: {sf}', _origin='markdown')]
    edges = []
    for line_no, line in enumerate(lines, 1):
        m = re.match(r'^(#{2,4})\s+(.+)', line)
        if not m and not (bullets and re.match(r'^\s*[-*]\s+\S', line)):
            continue
        heading = re.sub(r'\s*#+$', '', m.group(2)).strip() if m else re.sub(r'^\s*[-*]\s+', '', line).strip()
        if len(heading) < 3:
            continue
        nid = root_id + '_' + slug(heading) + '_' + str(line_no)
        description = (' '.join(x.strip() for x in lines[line_no:line_no+5] if x.strip())[:300]
                       if m else heading[:500])
        nodes.append(dict(id=nid, label=heading, norm_label=heading.lower(), file_type='concept', source_file=sf,
                          source_location=f'L{line_no}', description=description, _origin='markdown'))
        edges.append(dict(source=root_id, target=nid, relation='contains', confidence='EXTRACTED',
                          confidence_score=1.0, source_file=sf, source_location=f'L{line_no}', weight=1.0))
    return nodes, edges


def community_for(sf, old_nodes, labels):
    same = Counter(n.get('community') for n in old_nodes if n.get('source_file') == sf and isinstance(n.get('community'), int))
    if same:
        return same.most_common(1)[0][0]
    folder = sf.rsplit('/', 1)[0] if '/' in sf else sf
    nearby = Counter(n.get('community') for n in old_nodes if n.get('source_file', '').startswith(folder + '/') and isinstance(n.get('community'), int))
    if nearby:
        return nearby.most_common(1)[0][0]
    return next(iter(labels))


def project_graph(files, previous, state):
    old = read(OUT / 'graph.json')
    corrections = read(Path(__file__).with_name('verified-corrections.json'))
    old_nodes = old['nodes']
    labels = {int(k): v for k, v in read(OUT / '.graphify_labels.json').items()}
    changed = {sf for sf in files if previous.get(sf, {}).get('sha256') != state[sf]['sha256']}
    removed = set(previous) - set(files)
    code = sorted(sf for sf in changed if sf.endswith(('.luau', '.py')))
    docs = sorted(changed - set(code))
    # MountainGen is hand-repaired in the curated graph. Retain those nodes and edges.
    replaced = set(code) - set(corrections['protected_sources'])
    nodes = [n.copy() for n in old_nodes if n.get('source_file') not in replaced | removed
             and not (n.get('source_file') in docs and n.get('_origin') == 'markdown')]
    keep_ids = {n['id'] for n in nodes}
    links = [e.copy() for e in old['links'] if e.get('source') in keep_ids and e.get('target') in keep_ids]
    if replaced:
        result = extract([files[sf] for sf in sorted(replaced)], cache_root=ROOT, root=ROOT)
        for n in result['nodes']:
            sf = n.get('source_file', '')
            if sf.startswith('src_legacy_v2/'):
                n['tags'] = ['legacy', 'v2']
            if sf.startswith('creatures/'):
                n['tags'] = ['codex-owned', 'read-only']
            cid = community_for(sf, old_nodes, labels)
            n['community'] = cid
            n['community_name'] = labels[cid]
        nodes.extend(result['nodes'])
        links.extend(result['edges'])
    for sf in code:
        if sf in corrections['protected_sources']:
            # Add newly declared functions that the Luau parser misses.
            existing = {n['label'] for n in nodes if n.get('source_file') == sf}
            root_id = slug(sf.removesuffix('.luau'))
            for line_no, line in enumerate(files[sf].read_text(encoding='utf-8-sig').splitlines(), 1):
                m = re.match(r'^(?:local function (\w+)|function (\w+)[.:](\w+))\(', line)
                if not m:
                    continue
                label = ((m.group(1) or m.group(3)) + '()')
                if label in existing:
                    continue
                nid = root_id + '_' + slug(label)
                cid = community_for(sf, old_nodes, labels)
                nodes.append(dict(id=nid, label=label, norm_label=label.lower(), file_type='code', source_file=sf,
                                  source_location=f'L{line_no}', supplement='hand-extracted; compound-assignment parser issue',
                                  community=cid, community_name=labels[cid], _origin='ast'))
                if any(n['id'] == root_id for n in nodes):
                    links.append(dict(source=root_id, target=nid, relation='contains', confidence='EXTRACTED',
                                      confidence_score=1.0, source_file=sf, source_location=f'L{line_no}', weight=1.0))
                existing.add(label)
    for sf in docs:
        new_nodes, new_edges = note_nodes(files[sf], sf, 'repo_doc_')
        cid = community_for(sf, old_nodes, labels)
        for n in new_nodes:
            n['community'] = cid
            n['community_name'] = labels[cid]
        nodes.extend(new_nodes)
        links.extend(new_edges)
    # Restore valid old cross-file relationships to re-extracted symbols.
    final_ids = {n['id'] for n in nodes}
    links.extend(e.copy() for e in old['links'] if e.get('source') in final_ids and e.get('target') in final_ids
                 and e.get('source_file') not in replaced)
    # The parser misses Luau declarations in some compound-assignment files.
    # Supplement only declarations verified in the current source text.
    supplement_files = set(code)
    for known in corrections['luau_supplement_paths']:
        if known in files and not any(n.get('source_file') == known and n.get('_origin') == 'verified_declaration' for n in nodes):
            supplement_files.add(known)
    for sf in sorted(supplement_files):
        if not sf.endswith('.luau') or sf.startswith('creatures/'):
            continue
        existing = {(n.get('label'), n.get('source_location')) for n in nodes if n.get('source_file') == sf}
        cid = community_for(sf, old_nodes, labels)
        for line_no, line in enumerate(files[sf].read_text(encoding='utf-8-sig').splitlines(), 1):
            m = re.match(r'^\s*(?:local\s+)?function\s+([\w.]+(?::\w+)?)\s*\(', line)
            if not m:
                continue
            label, loc = m.group(1) + '()', f'L{line_no}'
            if (label, loc) in existing or any(n.get('label') == label and n.get('source_file') == sf for n in nodes):
                continue
            nodes.append(dict(id='luau_decl_' + hashlib.sha256(f'{sf}:{label}:{loc}'.encode()).hexdigest()[:16],
                              label=label, norm_label=label.lower(), file_type='code', source_file=sf,
                              source_location=loc, description=line.strip()[:240], _origin='verified_declaration',
                              provenance={'path': sf, 'line': line_no, 'method': 'Luau declaration regex'},
                              confidence='EXTRACTED', confidence_score=0.95,
                              community=cid, community_name=labels[cid]))
            existing.add((label, loc))
    # Parser misses data-only files: retain a resolvable source summary.
    source_set = {n.get('source_file') for n in nodes}
    for sf in files:
        if sf not in source_set:
            cid = community_for(sf, old_nodes, labels)
            nodes.append(dict(id='source_' + slug(sf), label=Path(sf).name, norm_label=Path(sf).name.lower(),
                              file_type='document', source_file=sf, source_location='L1',
                              description='Source file indexed without parser symbols.', _origin='source',
                              community=cid, community_name=labels[cid]))
    for n in nodes:
        cid = n.get('community')
        if isinstance(cid, int) and cid in labels:
            n['community_name'] = labels[cid]
    # Deduplicate by ID; discard dangling references and duplicate endpoint/relation edges.
    by_id = {n['id']: n for n in nodes}
    seen = set()
    clean_links = []
    for e in links:
        pair = (e.get('source'), e.get('target'), e.get('relation'))
        if pair[0] not in by_id or pair[1] not in by_id or pair in seen:
            continue
        seen.add(pair)
        clean_links.append(e)
    graph = {**old, 'nodes': list(by_id.values()), 'links': clean_links}
    graph['hyperedges'] = [h for h in old.get('hyperedges', []) if all(i in by_id for i in h.get('nodes', []))]
    write(OUT / 'graph.json', graph)
    analysis_path = OUT / '.graphify_analysis.json'
    analysis = read(analysis_path) if analysis_path.exists() else {}
    communities = defaultdict(list)
    for n in graph['nodes']:
        communities[str(n.get('community', 0))].append(n['id'])
    analysis['communities'] = dict(communities)
    analysis['cohesion'] = {}
    analysis['gods'] = []
    analysis['surprises'] = []
    analysis['questions'] = []
    write(analysis_path, analysis)
    # Keep the extraction cache aligned for Graphify's query and report tools.
    write(OUT / '.graphify_extract.json', {'nodes': graph['nodes'], 'edges': graph['links'],
                                           'hyperedges': graph['hyperedges'], 'input_tokens': 0, 'output_tokens': 0})
    write(OUT / 'manifest.json', state)
    (OUT / 'GRAPH_REPORT.md').write_text(f'# Climb & Collect Graph Report\n\nRefreshed {STAMP}.\n\n'
        f'- Nodes: {len(graph["nodes"])}\n- Edges: {len(graph["links"])}\n- Communities: {len(set(n.get("community") for n in graph["nodes"]))}\n'
        f'- Changed inputs: {len(changed)}; removed: {len(removed)}\n'
        f'- Curated community IDs and labels retained. Existing semantic relationships retained when endpoints still exist.\n', encoding='utf-8')
    return graph, changed, removed


def vault_files():
    names = ('Climb & Collect/Climb & Collect.md', 'Climb & Collect/Decisions.md',
             'Climb & Collect/Milestones.md', 'Climb & Collect/Open Questions.md')
    paths = [VAULT / n for n in names]
    paths += list((VAULT / 'Roblox Shared').glob('*.md'))
    return {p.relative_to(VAULT).as_posix(): p for p in paths if p.exists()}


def backup_vault():
    before = {sf: digest(p) for sf, p in vault_files().items()}
    target = Path.home() / 'Documents' / f'vault-backup-graphify-{STAMP}.zip'
    all_files = [p for folder in ('Climb & Collect', 'Roblox Shared') for p in (VAULT / folder).rglob('*') if p.is_file()]
    with zipfile.ZipFile(target, 'x', zipfile.ZIP_DEFLATED) as z:
        for p in all_files:
            z.write(p, p.relative_to(VAULT).as_posix())
    with zipfile.ZipFile(target) as z:
        assert len(z.namelist()) == len(all_files)
        assert all(hashlib.sha256(z.read(p.relative_to(VAULT).as_posix())).hexdigest() == digest(p) for p in all_files)
    return target, before


def vault_graph(files, state):
    prior = read(WORK / 'out/graph.json')
    previous = read(WORK / 'vault-manifest.json') if (WORK / 'vault-manifest.json').exists() else {}
    changed = {sf for sf in files if previous.get(sf, {}).get('sha256') != state[sf]['sha256']}
    represented = {n.get('source_file', '').removeprefix('src/') for n in prior['nodes']}
    changed |= set(files) - represented
    # Keep the verified semantic concepts and add current note structure. Generated exports are excluded.
    nodes = [n.copy() for n in prior['nodes'] if n.get('source_file', '').removeprefix('src/') in files
             and (n.get('_origin') != 'markdown' or n.get('source_file', '').removeprefix('src/') not in changed)]
    semantic_nodes = [n for n in nodes if n.get('_origin') != 'markdown']
    keep = {n['id'] for n in nodes}
    edges = [e.copy() for e in prior['links'] if e['source'] in keep and e['target'] in keep]
    for sf, path in files.items():
        if sf not in changed:
            continue
        nn, ee = note_nodes(path, 'src/' + sf, 'vault_note_', bullets=True)
        for n in nn:
            n['graph'] = 'vault'
            n['community'] = 122 + (0 if sf.startswith('Climb & Collect/') else 4)
            n['community_name'] = 'Climb & Collect Notes' if sf.startswith('Climb & Collect/') else 'Roblox Shared Tooling'
        nodes.extend(nn)
        edges.extend(ee)
        doc_id = nn[0]['id']
        for n in semantic_nodes:
            if n.get('source_file') == 'src/' + sf:
                edges.append(dict(source=doc_id, target=n['id'], relation='documents', confidence='EXTRACTED',
                                  confidence_score=1.0, source_file='src/' + sf, weight=1.0))
    ids = {n['id'] for n in nodes}
    edges = [e for e in edges if e['source'] in ids and e['target'] in ids]
    graph = {**prior, 'nodes': nodes, 'links': edges}
    write(WORK / 'out/graph.json', graph)
    write(WORK / 'vault-manifest.json', state)
    return graph


def merge(project, vault):
    old = read(WORK / 'merged-graph.json')
    nodes = []
    for repo, graph in (('repo', project), ('vault', vault)):
        for n in graph['nodes']:
            n = n.copy()
            n['local_id'] = n['id']
            n['id'] = repo + '::' + n['id']
            n['repo'] = repo
            nodes.append(n)
    ids = {n['id'] for n in nodes}
    edges = []
    for repo, graph in (('repo', project), ('vault', vault)):
        for e in graph['links']:
            e = e.copy()
            e['source'] = repo + '::' + e['source']
            e['target'] = repo + '::' + e['target']
            if e['source'] in ids and e['target'] in ids:
                edges.append(e)
    # Retain prior explicit bridges whose endpoints still exist.
    for e in old['links']:
        if e['source'].split('::')[0] != e['target'].split('::')[0] and e['source'] in ids and e['target'] in ids:
            e = e.copy()
            e.setdefault('provenance', {'method': 'retained reviewed bridge', 'review': 'prior curated graph'})
            e.setdefault('reason', 'Existing semantic link with current endpoints')
            edges.append(e)
    # Verified links from a vault note to the precise repo document it names.
    doc_by_name = defaultdict(list)
    for n in project['nodes']:
        if n.get('file_type') == 'document':
            doc_by_name[Path(n.get('source_file', '')).name.lower()].append(n)
    for n in vault['nodes']:
        sf = n.get('source_file', '').removeprefix('src/')
        if not sf or not (VAULT / sf).exists():
            continue
        description = n.get('description', '')
        for name, matches in doc_by_name.items():
            if re.search(r'(?<![\w.-])' + re.escape(name) + r'(?![\w.-])', description.lower()) and name.endswith('.md'):
                if len(matches) != 1:
                    continue  # ambiguous basename; quality report requests review
                for match in matches:
                    edges.append(dict(source='vault::' + n['id'], target='repo::' + match['id'],
                                      relation='references', confidence='EXTRACTED', confidence_score=0.95,
                                      source_file='src/' + sf, weight=1.0,
                                      provenance={'method': 'exact document basename', 'vault_path': sf,
                                                  'document_path': match['source_file']},
                                      reason='Vault text names the unique indexed document'))
    # Stable, reviewed topic bridges. The right-hand side names current source files;
    # nodes are selected from those exact files, so deleted sources never gain links.
    bridges = {
        'vault_milestones_stage34_perf_fix': ['evidence/perf_P1/perf_after.md', 'evidence/perf_P1/perf_report.md'],
        'vault_climb_collect_status_unverified': ['design/expedition-handoff-2026-10-22.md', 'design/fairground-polish-handoff-2026-10-22.md'],
        'vault_open_questions_device_targets_mobile_perf': ['master.md', 'design/fairground-polish-handoff-2026-10-22.md'],
        'vault_open_questions_day_night_clock': ['src/core/server/Clock.luau', 'design/v5-trails-and-mountain-plan.md'],
        'vault_open_questions_phone_human_playtest': ['master.md', 'design/fairground-polish-handoff-2026-10-22.md'],
        'vault_studio_mcp_gotchas_unfocused_15fps': ['CLAUDE.md', 'tools/perf_probe.luau'],
        'vault_open_questions_ui_round': ['design/v5-ui-plan.md', 'design/expedition-ui.md'],
        'vault_open_questions_verify_real_datastore': ['src/core/server/Store.luau', 'design/expedition-persistence-home.md'],
        'vault_milestones_v3_ascent_first_draft': ['design/v3-morning-report.md', 'src/world/BuildAll.luau'],
        'vault_climb_collect_status_stage3_5_done': ['CLAUDE.md', 'design/v4-plan.md'],
        'vault_milestones_v4_p1_ledge_section': ['evidence/v4_P1/P1_report.md', 'src/world/LedgeP1.luau'],
        'vault_milestones_v4_p2_shepherd_stretch': ['evidence/v4_P2/P2_report.md', 'src/world/ShepherdP2.luau'],
        'vault_open_questions_approve_v4_p3': ['design/v4-plan.md', 'evidence/v4_P3_report.md'],
        'vault_decisions_summit_3200_routes': ['master.md', 'src/world/WorldConfig.luau'],
        'vault_studio_mcp_gotchas_open_application_update': ['CLAUDE.md'],
        'vault_studio_mcp_gotchas_taskbar_click': ['CLAUDE.md'],
        'vault_studio_mcp_gotchas_save_procedure': ['CLAUDE.md'],
        'vault_workflow_src_sync_checksum': ['tools/sync_core.luau', 'CLAUDE.md'],
        'vault_studio_mcp_gotchas_execute_luau_own_vm': ['CLAUDE.md'],
        'vault_studio_mcp_gotchas_multi_edit_replace_all': ['CLAUDE.md'],
        'vault_milestones_core_loop_first_draft': ['design/core-run-report.md', 'src/runtime/CC_CoreService.server.luau'],
        'vault_decisions_v5_ui_round': ['design/v5-ui-plan.md', 'design/references-ui-index.md'],
        'vault_decisions_v5_round3_feature_sections': ['design/v5-trails-and-mountain-plan.md', 'src/world/TraverseKit.luau'],
        'vault_open_questions_art_pass_stubs': ['master.md', 'design/expedition-handoff-2026-10-22.md'],
        'vault_decisions_server_authoritative_claims': ['src/core/server/Claims.luau', 'src/core/server/Bank.luau'],
        'vault_workflow_checkpoint_archive': ['tools/checkpoint.luau', 'CLAUDE.md'],
        'vault_workflow_evidence_per_milestone': ['CLAUDE.md', 'master.md'],
        'vault_decisions_max_two_checkpoints': ['CLAUDE.md', 'tools/checkpoint.luau'],
    }
    project_by_file = defaultdict(list)
    for n in project['nodes']:
        project_by_file[n.get('source_file')].append(n)
    for vault_id, paths in bridges.items():
        source = 'vault::' + vault_id
        if source not in ids:
            continue
        for path in paths:
            options = project_by_file.get(path, [])
            # Prefer a document/root node, then a named symbol from the exact file.
            options = sorted(options, key=lambda n: (n.get('file_type') != 'document', n.get('source_location') not in (None, 'L1')))
            if options:
                edges.append(dict(source=source, target='repo::' + options[0]['id'], relation='conceptually_related_to',
                                  confidence='INFERRED', confidence_score=0.82, source_file=path, weight=1.0,
                                  provenance={'method': 'reviewed topic bridge', 'vault_node': vault_id,
                                              'source_path': path},
                                  reason='Curated topic-to-source mapping; source path and node still exist'))
    seen = set()
    unique = []
    for e in edges:
        sig = (e['source'], e['target'], e.get('relation'))
        if sig not in seen:
            seen.add(sig)
            unique.append(e)
    graph = {'directed': False, 'multigraph': False, 'graph': {'schema_version': 1}, 'nodes': nodes,
             'links': unique, 'hyperedges': []}
    write(WORK / 'merged-graph.json', graph)
    return graph


def export(graph, backup, before):
    folder = EXPORT / 'exports' / STAMP
    assert not folder.exists()
    folder.mkdir(parents=True)
    grouped = defaultdict(list)
    for n in graph['nodes']:
        grouped[(n.get('repo'), n.get('community'), n.get('community_name'))].append(n)
    links = []
    canvas_nodes = []
    canvas_edges = []
    for idx, ((repo, cid, name), members) in enumerate(sorted(grouped.items(), key=lambda x: (x[0][0], x[0][1] or 0))):
        name = name or f'{repo} Community {cid}'
        filename = f'Hub {repo} {cid} - {slug(name)}.md'
        lines = [f'# {name}', '', f'- Graph: {repo}; community: {cid}; nodes: {len(members)}',
                 f'- Query: `python -m graphify query "{name}" --graph graphify-out/graph.json`', '', '## Key nodes', '']
        for n in members[:25]:
            sf = n.get('source_file', '')
            loc = n.get('source_location') or ''
            lines.append(f'- **{n.get("label", n["id"])}** — `{sf}{":" + loc if loc else ""}`')
        notes = sorted({n.get('source_file', '').removeprefix('src/') for n in members if n.get('repo') == 'vault'})
        if notes:
            lines += ['', '## Existing notes', '']
            lines += [f'- [[{s.removesuffix(".md")}]]' for s in notes if s.endswith('.md')]
        (folder / filename).write_text('\n'.join(lines) + '\n', encoding='utf-8')
        links.append(f'- [[Climb & Collect/graphify/exports/{STAMP}/{filename.removesuffix(".md")}|{name}]] ({repo} {cid}; {len(members)} nodes)')
        canvas_nodes.append({'id': f'c{idx}', 'type': 'file', 'file': f'Climb & Collect/graphify/exports/{STAMP}/{filename}',
                             'x': (idx % 12) * 330, 'y': (idx // 12) * 220, 'width': 290, 'height': 160})
    # Canvas edge: one per distinct linked community pair, bounded for readability.
    node_community = {n['id']: (n.get('repo'), n.get('community'), n.get('community_name')) for n in graph['nodes']}
    index_by_group = {k: i for i, k in enumerate(sorted(grouped, key=lambda x: (x[0], x[1] or 0)))}
    pairs = set()
    for e in graph['links']:
        a, b = node_community.get(e['source']), node_community.get(e['target'])
        if a and b and a != b:
            pair = tuple(sorted((index_by_group[a], index_by_group[b])))
            if pair not in pairs and len(pairs) < 250:
                pairs.add(pair)
                canvas_edges.append({'id': f'e{len(pairs)}', 'fromNode': f'c{pair[0]}', 'toNode': f'c{pair[1]}'})
    canvas = {'nodes': canvas_nodes, 'edges': canvas_edges}
    write(folder / 'Graph Map.canvas', canvas)
    cross = [e for e in graph['links'] if e['source'].split('::')[0] != e['target'].split('::')[0]]
    index = ['# Climb & Collect Graph Index', '', f'Generated {STAMP}.', '',
             f'- Project: {sum(n["repo"] == "repo" for n in graph["nodes"])} nodes',
             f'- Vault: {sum(n["repo"] == "vault" for n in graph["nodes"])} nodes',
             f'- Merged: {len(graph["nodes"])} nodes / {len(graph["links"])} edges',
             f'- Communities: {len(grouped)}; cross-graph links: {len(cross)}',
             f'- Backup: `{backup}`',
             f'- Canvas: [[Climb & Collect/graphify/exports/{STAMP}/Graph Map.canvas|Graph Map]]', '',
             '## Community hubs', ''] + links
    (folder / 'Graph Index.md').write_text('\n'.join(index) + '\n', encoding='utf-8')
    # The active pointer is one small index; historical exports remain versioned.
    active = EXPORT / 'Graph Index.md'
    active.write_text(f'# Climb & Collect Graph\n\nCurrent export: [[Climb & Collect/graphify/exports/{STAMP}/Graph Index|Graph Index]]\n\nCanvas: [[Climb & Collect/graphify/exports/{STAMP}/Graph Map.canvas|Graph Map]]\n', encoding='utf-8')
    after = {sf: digest(p) for sf, p in vault_files().items()}
    unexpected = {sf for sf in before if after.get(sf) != before[sf]}
    assert not unexpected, f'Unexpected vault source note changes: {unexpected}'
    return folder, len(grouped), len(cross)


def main():
    deep = '--deep' in sys.argv[1:]
    files = source_files()
    old_manifest = read(OUT / 'manifest.json')
    state = file_state(files, old_manifest, deep=deep)
    current = all(old_manifest.get(sf, {}).get('sha256') == state[sf]['sha256'] for sf in files) and set(old_manifest) == set(files)
    vf = vault_files()
    vm = read(WORK / 'vault-manifest.json') if (WORK / 'vault-manifest.json').exists() else {}
    vault_state = file_state(vf, vm, deep=deep)
    vault_current = all(vm.get(sf, {}).get('sha256') == vault_state[sf]['sha256'] for sf in vf) and set(vm) == set(vf)
    if current and vault_current and (WORK / 'merged-graph.json').exists():
        from quality import audit
        check = audit(read(OUT / 'graph.json'), read(WORK / 'out/graph.json'), read(WORK / 'merged-graph.json'),
                      files, vf, state, vault_state, changed=[])
        defects = (check['coverage']['missing_project_files'] or check['coverage']['missing_vault_notes'] or
                   check['graph']['broken_edges'] or check['graph']['weak_community_ids'])
        if not defects:
            from benchmark import main as benchmark
            if benchmark():
                return 1
            print('NO CHANGE: project and vault inputs match manifests')
            return 0
        print('Graph quality defect detected; rebuilding from current inputs:', defects)
    backup, before = backup_vault()
    print('Verified backup:', backup)
    project, changed, removed = project_graph(files, old_manifest, state)
    vault = vault_graph(vf, vault_state)
    merged = merge(project, vault)
    from quality import audit
    audit(project, vault, merged, files, vf, state, vault_state, changed=changed)
    folder, communities, cross = export(merged, backup, before)
    for graph, tag in ((OUT / 'graph.json', 'climb-collect-project'), (WORK / 'out/graph.json', 'climb-collect-vault')):
        subprocess.run([sys.executable, '-m', 'graphify', 'global', 'add', str(graph), '--as', tag], check=True, cwd=ROOT)
    subprocess.run([sys.executable, '-m', 'graphify', 'export', 'html', '--graph', str(OUT / 'graph.json')], check=True, cwd=ROOT)
    from benchmark import main as benchmark
    if benchmark():
        return 1
    print(f'Project {len(project["nodes"])} nodes/{len(project["links"])} edges; vault {len(vault["nodes"])} nodes/{len(vault["links"])} edges')
    print(f'Merged {len(merged["nodes"])} nodes/{len(merged["links"])} edges; {communities} hubs; {cross} cross links; changed {len(changed)} removed {len(removed)}')
    print('Export:', folder)
    return 0


if __name__ == '__main__':
    sys.exit(main())
