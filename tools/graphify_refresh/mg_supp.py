import json,re
from pathlib import Path
g=json.load(open('graphify-out/graph.json'))
a=json.load(open('graphify-out/.graphify_ast_new.json'))
def run(src, prefix, pool_nodes, pool_edges, tag):
    lines=Path(src).read_text(encoding='utf-8').splitlines()
    defs=[]
    for i,l in enumerate(lines,1):
        m=re.match(r'^local function (\w+)\(',l)
        if m: defs.append((i,m.group(1),m.group(1)+'()',prefix+'_'+m.group(1).lower())); continue
        m=re.match(r'^function (\w+)[.:](\w+)\(',l)
        if m: defs.append((i,m.group(2),f'{m.group(1)}.{m.group(2)}()',prefix+'_'+m.group(1).lower()+'_'+m.group(2).lower()))
    nodes={n['id']:n for n in pool_nodes if n['source_file']==src}
    edges=[e for e in pool_edges if e.get('source_file')==src]
    root=prefix
    new=0
    for ln,short,label,nid in defs:
        if nid not in nodes:
            n={'id':nid,'label':label,'_callable':True,'_origin':'ast','file_type':'code','norm_label':label.lower(),'source_file':src,'source_location':f'L{ln}','supplement':'hand-extracted (parser error on compound assignment)'}
            if tag: n['tags']=tag
            nodes[nid]=n; new+=1
            edges.append({'source':root,'target':nid,'relation':'contains','confidence':'EXTRACTED','confidence_score':1.0,'source_file':src,'source_location':f'L{ln}','weight':1.0,'_origin':'ast'})
    have={(e['source'],e['relation'],e['target']) for e in edges}
    names={d[1]:d[3] for d in defs}
    for k,(ln,short,label,nid) in enumerate(defs):
        end=defs[k+1][0] if k+1<len(defs) else len(lines)+1
        body='\n'.join(lines[ln:end-1])
        for nm,tid in names.items():
            if tid==nid: continue
            if re.search(r'(?<![\w])(?:Gen[.:])?'+re.escape(nm)+r'\(',body):
                key=(nid,'calls',tid)
                if key not in have:
                    have.add(key); edges.append({'source':nid,'target':tid,'relation':'calls','confidence':'EXTRACTED','confidence_score':1.0,'context':'call','source_file':src,'source_location':f'L{ln}','weight':1.0,'_origin':'ast'})
    print(src,len(defs),'defs',new,'new nodes')
    return list(nodes.values()),edges
n1,e1=run('src/world/MountainGen.luau','src_world_mountaingen',g['nodes'],g['links'],None)
n2,e2=run('src_legacy_v2/MountainGen.luau','src_legacy_v2_mountaingen',a['nodes'],a['edges'],['legacy','v2'])
# tag legacy nodes
for n in n2: n.setdefault('tags',['legacy','v2'])
out={'nodes':n1+n2,'edges':e1+e2}
Path('graphify-out/.graphify_mg_supp.json').write_text(json.dumps(out,ensure_ascii=False),encoding='utf-8')
