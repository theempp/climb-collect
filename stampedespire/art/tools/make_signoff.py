"""Zone sign-off sheet: the zone's r2 header (LOOKDEV header box) above in-game shots.
python art/tools/make_signoff.py ZONE OUT.png SHOT1 [SHOT2 ...]"""
import sys
from PIL import Image, ImageDraw

HEAD = {1: ("r2-zone1-taiga.png", (540, 0, 1150, 122)), 2: ("r2-zone2-crevasse.png", (400, 0, 1344, 165)),
        3: ("r2-zone3-obsidian.png", (460, 0, 1180, 122)), 4: ("r2-zone4-aurora.png", (400, 0, 1190, 178))}
z, out, shots = int(sys.argv[1]), sys.argv[2], sys.argv[3:]
f, box = HEAD[z]
W = 1400
head = Image.open("concepts/2026-10-29/" + f).convert("RGB").crop(box)
head = head.resize((W, round(head.height * W / head.width)))
ims = [head] + [Image.open(s).convert("RGB") for s in shots]
ims = [ims[0]] + [i.resize((W, round(i.height * W / i.width))) for i in ims[1:]]
sheet = Image.new("RGB", (W, sum(i.height for i in ims) + 8 * len(ims)), (20, 20, 24))
y = 0
for i, im in enumerate(ims):
    sheet.paste(im, (0, y))
    ImageDraw.Draw(sheet).text((8, y + 6), "r2 sheet header" if i == 0 else "in game", fill=(255, 255, 0))
    y += im.height + 8
sheet.save(out)
print("SIGNOFF", out, sheet.size)
