"""motion_sheet.py <frames_dir> <demo> <out.jpg> [n=12] [crop=x0,y0,x1,y1 (fractions)] : contact sheet of a capture_motion.py
sequence, n frames evenly spaced in motion time, each labelled with its time (s)."""
import pathlib, re, sys
from PIL import Image, ImageDraw

d, demo, out = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
n = int(sys.argv[4]) if len(sys.argv) > 4 else 12
crop = [float(v) for v in sys.argv[5].split(',')] if len(sys.argv) > 5 else None
frames = sorted(((float(re.search(r'_t([\d.]+)\.png$', f.name).group(1)), f) for f in d.glob(f'{demo}_*_t*.png')))
if not frames: raise SystemExit('no frames for ' + demo)
end = frames[-1][0]; pick = []
for i in range(n):
    t = end * i / (n - 1); pick.append(min(frames, key=lambda x: abs(x[0] - t)))
imgs = []
for t, f in pick:
    im = Image.open(f).convert('RGB')
    if crop: w, h = im.size; im = im.crop((int(crop[0] * w), int(crop[1] * h), int(crop[2] * w), int(crop[3] * h)))
    im.thumbnail((560, 400)); dr = ImageDraw.Draw(im); dr.rectangle((0, 0, 92, 26), fill=(0, 0, 0)); dr.text((6, 6), f'{t:.2f} s', fill=(255, 255, 255))
    imgs.append(im)
cols = 4; w, h = imgs[0].size; rows = (len(imgs) + cols - 1) // cols
sheet = Image.new('RGB', (cols * w + (cols + 1) * 6, rows * h + (rows + 1) * 6), (30, 30, 30))
for i, im in enumerate(imgs): sheet.paste(im, (6 + (i % cols) * (w + 6), 6 + (i // cols) * (h + 6)))
sheet.save(out, quality=85); print(out, sheet.size)
