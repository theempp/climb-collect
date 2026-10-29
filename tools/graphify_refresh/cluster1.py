import json,collections
from pathlib import Path
from graphify.build import build_from_json
from graphify.cluster import cluster, score_all
ex=json.load(open('graphify-out/.graphify_extract.json'))
ids={n['id'] for n in ex['nodes']}
remap={'script_parent_worldconfig':'src_world_worldconfig','script_parent_climbkit':'src_world_climbkit','script_parent_traversekit':'src_world_traversekit'}
for k in ['bank','clock','inventory','profile','progression','store']: remap['script_parent_'+k]='src_core_server_'+k
for k,v in remap.items(): assert v in ids,v
ex['nodes']=[n for n in ex['nodes'] if n['id'] not in remap]
for e in ex['edges']:
    e['source']=remap.get(e['source'],e['source']); e['target']=remap.get(e['target'],e['target'])
json.dump(ex,open('graphify-out/.graphify_extract.json','w'),ensure_ascii=False)
G=build_from_json(ex,root='.',directed=False)
com=cluster(G); coh=score_all(G,com)
print(G.number_of_nodes(),G.number_of_edges(),len(com))
json.dump({'communities':{str(k):v for k,v in com.items()},'cohesion':{str(k):v for k,v in coh.items()}},open('graphify-out/.graphify_com.json','w'))
out=[]
for cid,ns in sorted(com.items()):
    deg=sorted(ns,key=lambda n:-G.degree(n))
    files=collections.Counter(G.nodes[n].get('source_file','') for n in ns).most_common(2)
    out.append(f"{cid} n={len(ns)} coh={coh[cid]:.2f} files={[f for f,_ in files]} top={[G.nodes[n].get('label') for n in deg[:5]]}")
Path('graphify-out/.com_summary.txt').write_text('\n'.join(out),encoding='utf-8')
