"""Create a local comparison viewer that references unmodified Studio captures."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];EV=ROOT/'evidence/mountain_quality_2026-10-26'
views=json.loads((EV/'views.json').read_text())
names=['Blossom Gardens','Azure Falls','Sunstone Desert','Violet Crystals','Inferno Heights','Astral Crown']
items=[]
for v in views:
    name=v['id'].replace('-',' ').title()
    if v['id'].startswith('section-'):name=names[int(v['id'].split('-')[1])-1]+' / '+v['id'].split('-')[-1]
    items.append({'id':v['id'],'name':name})
for k,name in enumerate(names,1):items.append({'id':f'phone-section-{k}-terrace','name':name+' / Galaxy A06 simulator'})
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Mountain quality • local comparison</title>
<style>body{margin:0;background:#101918;color:#ebeee6;font:16px system-ui,sans-serif}main{max-width:1500px;margin:40px auto;padding:0 28px}h1{font-size:30px;font-weight:600;margin:0 0 12px}p{color:#b8c7bd;max-width:1000px;line-height:1.6}select{padding:12px;margin:16px 0 24px;background:#243530;color:#fff;border:1px solid #688475;border-radius:6px;font:inherit;min-width:300px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:0}figcaption{margin:0 0 12px;font-weight:600}img{width:100%;height:auto;display:block;border:1px solid #3d5148}a{color:#b7d7c3}footer{margin-top:24px;color:#a4b9ac;font-size:14px}@media(max-width:800px){.pair{grid-template-columns:1fr}}</style>
<main><h1>Mountain quality comparison</h1><p>Same camera positions, six existing biomes, preserved mountain terrain. These are original Studio captures. Phone images show a simulator; they are not physical-device evidence.</p><select id="view" aria-label="Comparison viewpoint"></select><div class="pair"><figure><figcaption>Before • Review03 SprintEntrances</figcaption><a id="beforeLink"><img id="before" alt="Before mountain upgrade"></a></figure><figure><figcaption>After • MountainQuality Review01</figcaption><a id="afterLink"><img id="after" alt="After mountain upgrade"></a></figure></div><footer>Open either image for its full capture. Gameplay, performance, preservation and limitations are recorded in <a href="../../design/mountain-quality-overnight-report.md">the morning report</a>.</footer></main><script>
const items=ITEMS;const select=document.getElementById('view');for(const item of items){const opt=document.createElement('option');opt.value=item.id;opt.textContent=item.name;select.append(opt)}
function update(){for(const side of ['before','after']){const path=side+'/'+select.value+'.jpg';document.getElementById(side).src=path;document.getElementById(side+'Link').href=path}}
select.onchange=update;update();</script></html>'''.replace('ITEMS',json.dumps(items))
(EV/'comparison.html').write_text(html,encoding='utf-8')
print(EV/'comparison.html')
