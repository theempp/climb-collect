"""Package the local shop concept demo and crop its browser captures."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parent
html = (root / 'index.html').read_text(encoding='utf-8')
html = html.replace('<link rel="stylesheet" href="styles.css?v=5">', '<style>' + (root / 'styles.css').read_text(encoding='utf-8') + '</style>')
html = html.replace('<link rel="stylesheet" href="video-style.css?v=6">', '<style>' + (root / 'video-style.css').read_text(encoding='utf-8') + '</style>')
html = html.replace('<script src="app.js?v=5"></script>', '<script>' + (root / 'app.js').read_text(encoding='utf-8') + '</script>')
(root / 'CC-Shop-Artboards.html').write_text(html, encoding='utf-8')
previews = root / 'previews'
metadata = json.loads((previews / 'metadata.json').read_text())
sheet = Image.new('RGB', (1600, 1630), '#e9edf5')
draw = ImageDraw.Draw(sheet)
font = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 23)
draw.text((30, 20), 'CLIMB & COLLECT / SIX SHOP DIRECTIONS', font=font, fill='#183056')
for i, meta in enumerate(metadata):
    source = Image.open(previews / f'full-{i+1}.jpg')
    box = tuple(round(meta[k]) for k in ('x', 'y')) + (round(meta['x'] + meta['width']), round(meta['y'] + meta['height']))
    crop = source.crop(box)
    crop.save(previews / f'concept-{i+1}.jpg')
    x, y = 30 + (i % 2) * 790, 110 + (i // 2) * 500
    # Letterbox instead of distorting each independently sized artboard.
    crop.thumbnail((755, 450), Image.Resampling.LANCZOS)
    sheet.paste(crop, (x, y + (450 - crop.height) // 2))
    draw.text((x, y-33), f'0{i+1}  ' + meta['title'], font=font, fill='#183056')
sheet.save(previews / 'six-shop-concepts.jpg', quality=94)
print('Packaged portable HTML, six artboard crops, and comparison image.')
