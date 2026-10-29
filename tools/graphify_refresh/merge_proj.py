import json,shutil
from pathlib import Path
from graphify.build import build_merge
shutil.copy('graphify-out/graph.json','graphify-out/.graphify_old.json')
a=json.load(open('graphify-out/.graphify_ast_new.json'))
s=json.load(open('graphify-out/.graphify_mg_supp.json'))
# legacy MountainGen: replace ast nodes/edges by supplemented set
a['nodes']=[n for n in a['nodes'] if 'legacy_v2/MountainGen' not in n['source_file']]
a['edges']=[e for e in a['edges'] if 'legacy_v2/MountainGen' not in e.get('source_file','')]
a['nodes']+=s['nodes']; a['edges']+=s['edges']
# config doc-style nodes
desc={
 'src_core_shared_coreconfig':('CoreConfig','CoreConfig.luau: every core-loop number (rarity tiers, yields, XP, slots, Heartstone, claim holds, nets, walk speed, climb) shared by server and client; LOCKED vs PROPOSED tagged per value.','src/core/shared/CoreConfig.luau'),
 'src_world_worldconfig':('WorldConfig','WorldConfig.luau: V3 mountain layout + palette (map size, profile, biomes, camps, 4 routes, pads, rivers, material colors, player walk/slope).','src/world/WorldConfig.luau'),
 'tools_checkpoint':('checkpoint tool','checkpoint.luau: dev tool (Edit mode) that snapshots terrain, World, Lighting and sources into ServerStorage.CC_Checkpoints/<NAME>; never overwrites.','tools/checkpoint.luau'),
 'tools_publish_strip':('publish_strip tool','publish_strip.luau: dev tool run only in the Publish copy of the place; deletes Studio-only dev tools, generators, checkpoints and Tests before publishing.','tools/publish_strip.luau'),
}
for nid,(lab,d,sf) in desc.items():
    did=nid+'_desc'
    a['nodes'].append({'id':did,'label':lab+' (config/tool summary)','file_type':'document','source_file':sf,'source_location':'L1','description':d,'_origin':'semantic','norm_label':lab.lower()+' (config/tool summary)'})
    a['edges'].append({'source':did,'target':nid,'relation':'documents','confidence':'EXTRACTED','confidence_score':1.0,'source_file':sf,'source_location':'L1','weight':1.0,'_origin':'semantic'})
G=build_merge([a],graph_path='graphify-out/graph.json',root='.',directed=False)
print(G.number_of_nodes(),G.number_of_edges())
out={'nodes':[{'id':n,**d} for n,d in G.nodes(data=True)],
 'edges':[{**{k:v for k,v in d.items() if k not in('_src','_tgt','source','target')},'source':d.get('_src',u),'target':d.get('_tgt',v)} for u,v,d in G.edges(data=True)],
 'hyperedges':list(G.graph.get('hyperedges',[])),'input_tokens':0,'output_tokens':0}
Path('graphify-out/.graphify_extract.json').write_text(json.dumps(out,ensure_ascii=False),encoding='utf-8')
