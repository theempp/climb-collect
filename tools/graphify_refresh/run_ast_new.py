import json
from graphify.extract import extract
from pathlib import Path
r = json.loads(Path('graphify-out/.graphify_incremental.json').read_text(encoding='utf-8'))
files=[Path(f) for f in r['new_files']['code']]
res = extract(files, cache_root=Path('.'), root=Path('.'))
for n in res['nodes']:
    sf=n.get('source_file','')
    if sf.startswith('src_legacy_v2'): n['tags']=['legacy','v2']; n['label_note']='legacy V2 generator'
    if sf.startswith('creatures'): n['tags']=['codex-owned','read-only']
Path('graphify-out/.graphify_ast_new.json').write_text(json.dumps(res,ensure_ascii=False),encoding='utf-8')
print(len(res['nodes']),len(res['edges']))
