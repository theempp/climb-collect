import json
from pathlib import Path
from graphify.build import build_from_json
from graphify.analyze import god_nodes, surprising_connections, suggest_questions
from graphify.report import generate
from graphify.export import to_json, to_html
ex=json.load(open('graphify-out/.graphify_extract.json'))
inc=json.load(open('graphify-out/.graphify_incremental.json'))
cj=json.load(open('graphify-out/.graphify_com.json'))
com={int(k):v for k,v in cj['communities'].items()}; coh={int(k):v for k,v in cj['cohesion'].items()}
labels={int(k):v for k,v in json.load(open('graphify-out/.graphify_labels.json')).items()}
G=build_from_json(ex,root='.',directed=False)
det={'files':inc['files'],'total_files':inc['total_files'],'total_words':inc['total_words'],'skipped_sensitive':inc.get('skipped_sensitive',[]),'needs_graph':True}
gods=god_nodes(G); sur=surprising_connections(G,com); q=suggest_questions(G,com,labels)
assert to_json(G,com,'graphify-out/graph.json',community_labels=labels)
rep=generate(G,com,coh,labels,gods,sur,det,{'input':0,'output':0},'.',suggested_questions=q)
Path('graphify-out/GRAPH_REPORT.md').write_text(rep,encoding='utf-8')
json.dump({'communities':{str(k):v for k,v in com.items()},'cohesion':{str(k):v for k,v in coh.items()},'gods':gods,'surprises':sur,'questions':q},open('graphify-out/.graphify_analysis.json','w'),ensure_ascii=False,indent=1)
print(to_html(G,com,'graphify-out/graph.html',community_labels=labels))
print(G.number_of_nodes(),G.number_of_edges(),len(com))
