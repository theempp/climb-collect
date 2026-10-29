"""Retrieval acceptance check with fixed, source-verifiable queries."""
import json
import time

from query import freshness, search
from refresh import OUT, WORK, read, write

CASES = [
    ('server authoritative claims', 'src/core/server/Claims.luau'),
    ('real DataStore', 'Climb & Collect/Open Questions.md'),
    ('daily practice', 'src/core/server/DailyPractice.luau'),
    ('MountainGen', 'src/world/MountainGen.luau'),
    ('Graphify refresh', 'design/graphify-refresh-2026-10-22.md'),
]


def main():
    graph = read(WORK / 'merged-graph.json')
    prior_path = OUT / 'query-benchmark.json'
    prior = read(prior_path) if prior_path.is_file() else None
    results = []
    for term, expected in CASES:
        start = time.perf_counter()
        found = search(graph, term, limit=8)
        elapsed = round((time.perf_counter() - start) * 1000, 2)
        ranks = [i + 1 for i, n in enumerate(found) if expected.replace('/', '\\') in n['path'] or expected in n['path']]
        approx_tokens = round(len(json.dumps(found, ensure_ascii=False)) / 4)
        results.append({'query': term, 'expected_path': expected, 'rank': ranks[0] if ranks else None,
                        'runtime_ms': elapsed, 'approx_tokens': approx_tokens})
    passing = sum(x['rank'] is not None for x in results)
    report = {'freshness': freshness(), 'recall_at_8': passing / len(results),
              'mean_reciprocal_rank': round(sum(1 / x['rank'] for x in results if x['rank']) / len(results), 3),
              'mean_runtime_ms': round(sum(x['runtime_ms'] for x in results) / len(results), 2),
              'mean_approx_tokens': round(sum(x['approx_tokens'] for x in results) / len(results)),
              'cases': results}
    if prior:
        report['change_from_previous'] = {
            'recall_at_8': round(report['recall_at_8'] - prior['recall_at_8'], 3),
            'mean_reciprocal_rank': round(report['mean_reciprocal_rank'] - prior['mean_reciprocal_rank'], 3),
            'mean_runtime_ms': round(report['mean_runtime_ms'] - prior['mean_runtime_ms'], 2),
            'mean_approx_tokens': report['mean_approx_tokens'] - prior['mean_approx_tokens']}
    write(OUT / 'query-benchmark.json', report)
    print(json.dumps(report, indent=2))
    regressed = prior and report['mean_reciprocal_rank'] < prior['mean_reciprocal_rank'] - 0.1
    return 0 if passing == len(results) and report['freshness'] == 'CURRENT' and not regressed else 1


if __name__ == '__main__':
    raise SystemExit(main())
