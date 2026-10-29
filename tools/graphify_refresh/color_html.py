"""Write graphify-out/graph.html colored by ~10 project areas (instead of 122 community colors).
The community-colored view is kept as graph-communities.html. Run from the project root."""
import json, shutil, collections, os
from graphify.build import build_from_json
from graphify.export import to_html

ex = json.load(open('graphify-out/.graphify_extract.json'))
cj = json.load(open('graphify-out/.graphify_com.json'))
com = {int(k): v for k, v in cj['communities'].items()}
G = build_from_json(ex, root='.', directed=False)


def area(sf):
    sf = (sf or '').replace('\\', '/')
    if sf.startswith('src_legacy_v2'): return '8 Legacy V2 code'
    if sf.startswith('src/world'): return '1 World generation (src/world)'
    if sf.startswith('src/core'): return '2 Core loop (src/core)'
    if sf.startswith('src/runtime'): return '3 Runtime scripts (src/runtime)'
    if sf.startswith('tools'): return '4 Tools'
    if sf.startswith('creatures'): return '9 Creatures (Codex, read-only)'
    if sf.startswith('design'): return '5 Design docs'
    if sf.startswith('evidence'): return '6 Evidence reports'
    if sf.endswith('.md'): return '7 Project docs (CLAUDE / master / brief)'
    return None


own = {n: area(d.get('source_file')) for n, d in G.nodes(data=True)}
cm = {}
for c, ids in com.items():
    cnt = collections.Counter(own[i] for i in ids if own.get(i))
    cm[c] = cnt.most_common(1)[0][0] if cnt else '0 Other'
for n in own:
    if not own[n]:
        c = next((c for c, ids in com.items() if n in ids), None)
        own[n] = cm.get(c, '0 Other')

groups = collections.defaultdict(list)
for n, a in own.items():
    groups[a].append(n)
names = sorted(groups)
gcom = {i: groups[a] for i, a in enumerate(names)}
glab = {i: a[2:] for i, a in enumerate(names)}

if os.path.exists('graphify-out/graph.html') and not os.path.exists('graphify-out/graph-communities.html'):
    shutil.copy('graphify-out/graph.html', 'graphify-out/graph-communities.html')
print(to_html(G, gcom, 'graphify-out/graph.html', community_labels=glab))
print({glab[i]: len(v) for i, v in gcom.items()})
