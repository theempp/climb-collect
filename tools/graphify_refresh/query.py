"""Compact evidence-first query over the curated project/vault graph."""
import argparse
import json
import re
import sys
import time
from collections import defaultdict
from pathlib import Path

from refresh import OUT, ROOT, VAULT, WORK, file_state, read, source_files, vault_files


def freshness():
    current = True
    for manifest_path, files in ((OUT / 'manifest.json', source_files()),
                                 (WORK / 'vault-manifest.json', vault_files())):
        manifest = read(manifest_path)
        state = file_state(files, manifest)
        current &= set(files) == set(manifest) and all(
            state[sf]['sha256'] == manifest.get(sf, {}).get('sha256') for sf in files)
    return 'CURRENT' if current else 'STALE'


def source_path(node):
    sf = node.get('source_file', '')
    if node.get('repo') == 'vault':
        return VAULT / sf.removeprefix('src/')
    if sf.startswith('@memory/'):
        from refresh import MEMORY
        return MEMORY / sf.removeprefix('@memory/')
    return ROOT / sf


def excerpt(node, max_chars=185):
    path = source_path(node)
    if not path.is_file() or path.suffix not in ('.md', '.luau', '.py'):
        return '', None
    loc = node.get('source_location') or 'L1'
    match = re.match(r'L(\d+)', loc)
    line_no = int(match.group(1)) if match else 1
    lines = path.read_text(encoding='utf-8-sig', errors='replace').splitlines()
    if not lines:
        return '', None
    line_no = max(1, min(line_no, len(lines)))
    if node.get('_origin') == 'semantic' and line_no == 1:
        terms = {t for t in re.findall(r'[a-z0-9_]+', node.get('label', '').lower()) if len(t) > 3}
        if terms:
            scores = [len(terms & set(re.findall(r'[a-z0-9_]+', line.lower()))) for line in lines]
            best = max(range(len(scores)), key=scores.__getitem__)
            if scores[best] >= 2:
                line_no = best + 1
    return re.sub(r'\s+', ' ', lines[line_no - 1].strip())[:max_chars], f'L{line_no}'


def search(graph, query, limit=8):
    terms = re.findall(r'[a-z0-9_]+', query.lower())
    nodes = graph['nodes']
    direct = {}
    for n in nodes:
        label = n.get('label', '').lower()
        path = n.get('source_file', '').lower()
        desc = n.get('description', '').lower()
        score = sum((8 if t in label else 0) + (4 if t in path else 0) + (1 if t in desc else 0)
                    for t in terms)
        if query.lower() in label:
            score += 8
        if score:
            direct[n['id']] = score
    adjacency = defaultdict(list)
    for e in graph['links']:
        adjacency[e['source']].append(e['target'])
        adjacency[e['target']].append(e['source'])
    ranked = sorted(nodes, key=lambda n: (-direct.get(n['id'], 0),
                    -len(adjacency[n['id']]), n.get('source_file', ''), n['id']))
    selected = ranked[:limit]
    by_id = {n['id']: n for n in nodes}
    results = []
    for n in selected:
        if not direct.get(n['id']):
            continue
        linked = sorted((by_id[i] for i in adjacency[n['id']] if i in by_id),
                        key=lambda x: (-direct.get(x['id'], 0), x.get('source_file', '')))
        snippet, location = excerpt(n)
        results.append({'label': n.get('label'), 'path': str(source_path(n)),
                        'line': location or n.get('source_location'), 'date': time.strftime('%Y-%m-%d', time.localtime(source_path(n).stat().st_mtime)) if source_path(n).exists() else None,
                        'excerpt': snippet, 'score': direct[n['id']],
                        'related': [{'label': x.get('label'), 'path': x.get('source_file'),
                                     'relation': next((e.get('relation') for e in graph['links'] if {e['source'], e['target']} == {n['id'], x['id']}), None),
                                     'confidence': next((e.get('confidence') for e in graph['links'] if {e['source'], e['target']} == {n['id'], x['id']}), None)}
                                    for x in linked[:2]]})
    return results


def main():
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('query')
    parser.add_argument('--limit', type=int, default=6)
    parser.add_argument('--project', action='store_true')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    start = time.perf_counter()
    graph = read(OUT / 'graph.json' if args.project else WORK / 'merged-graph.json')
    results = search(graph, args.query, max(1, min(args.limit, 12)))
    status = freshness()
    payload = {'query': args.query, 'freshness': status, 'results': results,
               'runtime_ms': round((time.perf_counter() - start) * 1000),
               'approx_tokens': 0}
    if args.json:
        payload['approx_tokens'] = round(len(json.dumps(payload, ensure_ascii=False)) / 4)
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        lines = [f"{status} | {len(results)} results"]
        for n in results:
            lines += [f"- {n['label']} | {n['path']}:{n['line'] or 'L1'} | {n['date']}",
                      f"  {n['excerpt']}"]
            if n['related']:
                lines.append('  Links: ' + '; '.join(f"{x['label']} ({x['path']})" for x in n['related']))
        output = '\n'.join(lines)
        payload['approx_tokens'] = round(len(output) / 4)
        print(output)
        print(f"Runtime: {payload['runtime_ms']} ms | ~{payload['approx_tokens']} tokens")


if __name__ == '__main__':
    main()
