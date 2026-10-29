"""Build the offline HTML and crop observed browser captures without rescaling."""
from pathlib import Path
import json
from PIL import Image
root = Path(__file__).resolve().parent
html = (root / 'index.html').read_text(encoding='utf-8')
html = html.replace('<link rel="stylesheet" href="styles.css">', '<style>' + (root / 'styles.css').read_text(encoding='utf-8') + '</style>')
for name in ['model.js', 'art.js', 'app.js']:
    html = html.replace(f'<script src="{name}"></script>', '<script>' + (root / name).read_text(encoding='utf-8') + '</script>')
html = html.replace('<a href="../cc-shop-concepts/CC-Shop-Artboards.html">Original six concepts ↗</a>', '<span>Original six-concept prototype preserved in the source workspace.</span>')
(root / 'CC-Foothold-Exchange.html').write_text(html, encoding='utf-8')
for meta in (root / 'previews').glob('*-bounds.json'):
    name = meta.name.replace('-bounds.json', '')
    source = root / 'previews' / (name + '-full.png')
    if source.exists():
        box = json.loads(meta.read_text())
        image = Image.open(source)
        bounds = (max(0, round(box['x'])), max(0, round(box['y'])), min(image.width, round(box['right'])), min(image.height, round(box['bottom'])))
        image.crop(bounds).save(root / 'previews' / (name + '.png'))
print('Portable HTML and screenshot crops built.')
