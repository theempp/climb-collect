from pathlib import Path
root=Path(__file__).resolve().parent
p=root/'app.js'
s=p.read_text(encoding='utf-8')
s=s.replace("$('stage').innerHTML=view==='world'?worldView():renderers[current]();", "$('stage').innerHTML=(view==='world'||view==='context')?videoWorld():renderers[current]();")
s=s.replace("function showDialog(markup){$('purchase-body').innerHTML=markup;", "function showDialog(markup){$('purchase-dialog').classList.remove('reward-dialog');$('purchase-body').innerHTML=markup;")
s=s.replace("render();toast(id==='upgrade'?`${tiers[tier-1]}× permanent earnings unlocked in demo${tier===6?' · cap reached':''}`:`${p.name} added in demo`);", "render();rewardReveal(p);")
p.write_text(s,encoding='utf-8')
p=root/'index.html'
s=p.read_text(encoding='utf-8')
s=s.replace('<link rel="stylesheet" href="styles.css?v=4">','<link rel="stylesheet" href="styles.css?v=5"><link rel="stylesheet" href="video-style.css?v=5">')
s=s.replace('Five Pinterest references, six original directions.','Your simulator video + five pins, six original directions.')
s=s.replace('<button id="phone-mode"', '<button data-view="context">Offer moment</button><button id="reward-preview">Reward reveal</button><button id="phone-mode"')
s=s.replace('All five pins, translated.','Your video leads. The pins support it.')
s=s.replace('<div class="source-grid">','''<div class="video-study"><span class="video-mode-label">PRIMARY REFERENCE / 34.5-SECOND VIDEO</span><h3>Big icons. Glossy prices. Offers in the world.</h3><p>Reviewed across the full clip with two-second samples and enlarged frames. The video takes priority over the initial Pinterest-only direction. Typography and animation timings below are interpretations, not extracted assets.</p><div class="video-moments"><div><b>0–5s · The shop</b><span>Gold header, purple shell, bright framed cards, green bevelled CTAs, visible owned/locked states.</span></div><div><b>6–8s · The HUD</b><span>Large rainbow icon tiles, red multiplier bubbles and green “ONLY” price stickers remain visible during play.</span></div><div><b>18s · The offer moment</b><span>A gold coin-shortfall card sits beside a relevant upgrade. Translated into the cabin-upgrade preview.</span></div><div><b>26–28s · The reveal</b><span>Purple stage, sparkles and large reward cards. Translated into a guaranteed-item celebration after a simulated receipt.</span></div></div><p>The clip also shows timed boosts and random crates. These concepts retain your permanent coin upgrades and guaranteed bundles; the visual treatment is what transfers.</p></div><div class="source-grid">''')
s=s.replace('Translated into Summit Superstore.', 'Its split layout transfers to Prism Superstore; the video supplies its revised skin.')
s=s.replace('<script src="app.js?v=3"></script>', '<script src="app.js?v=5"></script>')
p.write_text(s,encoding='utf-8')
print('Applied video hierarchy, controls, and reference notes.')
