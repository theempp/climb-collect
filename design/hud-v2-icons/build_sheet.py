"""HUD v2 icons: raw 1024 generations -> 512 finals + contact sheet.
Colours from design/hud-v2-intel.md (panel.navy, ink, candy button bases/lips)."""
import glob, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ORDER = ["chest", "egg", "egg-cracked", "creature", "map", "gear", "coin", "gem", "heart",
         "sprint", "climb", "jump", "bat", "scroll", "calendar", "gift", "padlock"]
NAVY, INK = (0x1B, 0x2B, 0x5A), (0x14, 0x20, 0x3F)
# (base, shade/lip) pairs from intel §1
CANDY = [((0xFF, 0xC4, 0x14), (0xF2, 0x9A, 0x00), (0x8C, 0x4A, 0x1C)),  # cta yellow
         ((0x3F, 0xC5, 0x3A), (0x35, 0xA8, 0x32), (0x23, 0x89, 0x2A)),  # ok green
         ((0x3D, 0x8E, 0xF2), (0x34, 0x78, 0xCE), (0x24, 0x55, 0x93)),  # alt blue
         ((0xC6, 0x6C, 0xF2), (0xA8, 0x5C, 0xCE), (0x77, 0x41, 0x93)),  # tert purple
         ((0xEC, 0x3B, 0x4E), (0xD0, 0x33, 0x45), (0xA6, 0x1E, 0x33)),  # no red
         ((0xAE, 0xB6, 0xC0), (0x96, 0x9E, 0xA8), (0x69, 0x6E, 0x75))]  # off grey


def latest(name):
    vs = sorted(glob.glob(os.path.join(HERE, "raw", f"{name}.v*.png")),
                key=lambda p: int(p.rsplit(".v", 1)[1][:-4]))
    return vs[-1]


def final(name):
    im = Image.open(latest(name)).convert("RGBA")
    a = im.getchannel("A").point(lambda v: 255 if v > 8 else 0)
    im = im.crop(a.getbbox())
    s = 472 / max(im.size)  # ~92 % of 512, centred
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    out = Image.new("RGBA", (512, 512))
    out.paste(im, ((512 - im.width) // 2, (512 - im.height) // 2), im)
    out.save(os.path.join(HERE, f"{name}.png"))
    return out


def candy_tile(sz, base, shade, lip):
    """Intel §2 recipe: ink outline, lip, gradient face, top highlight band."""
    k = 4
    S = sz * k
    t = Image.new("RGBA", (S, S))
    d = ImageDraw.Draw(t)
    r, o, lipd = int(S * 0.22), max(int(S * 0.05), k * 2), int(S * 0.14)
    d.rounded_rectangle((0, 0, S - 1, S - 1), r, fill=INK)
    d.rounded_rectangle((o, o + lipd // 2, S - 1 - o, S - 1 - o), r - o, fill=lip)
    face = Image.new("RGBA", (S, S))
    fd = ImageDraw.Draw(face)
    top, bot = o, S - 1 - o - lipd
    for y in range(top, bot + 1):
        f = (y - top) / max(1, bot - top)
        fd.line((0, y, S, y), fill=tuple(int(base[i] + (shade[i] - base[i]) * f) for i in range(3)))
    m = Image.new("L", (S, S))
    ImageDraw.Draw(m).rounded_rectangle((o, top, S - 1 - o, bot), r - o, fill=255)
    t.paste(face, (0, 0), m)
    hl = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    hm = Image.new("L", (S, S))
    ImageDraw.Draw(hm).rounded_rectangle((o * 2, top + o, S - 1 - o * 2, top + int((bot - top) * 0.42)), r - o * 2, fill=70)
    hl.putalpha(hm)
    t = Image.alpha_composite(t, hl)
    return t.resize((sz, sz), Image.LANCZOS)


def font(px):
    for f in ("arialbd.ttf", "Arial.ttf"):
        try:
            return ImageFont.truetype(f, px)
        except OSError:
            pass
    return ImageFont.load_default()


icons = {n: final(n) for n in ORDER}
COLS, CELL, PAD = 6, 200, 24
rows = -(-len(ORDER) // COLS)
W = COLS * CELL + PAD * 2
secA = rows * (CELL + 28)
secB = rows * (CELL + 28)
secC = 120
H = 60 + secA + 50 + secB + 50 + secC + PAD
sheet = Image.new("RGB", (W, H), (0x10, 0x18, 0x34))
d = ImageDraw.Draw(sheet)
d.text((PAD, 18), "HUD v2 icons - on panel.navy #1B2B5A", fill="white", font=font(24))
y0 = 60
for i, n in enumerate(ORDER):
    x, y = PAD + (i % COLS) * CELL, y0 + (i // COLS) * (CELL + 28)
    d.rounded_rectangle((x + 6, y, x + CELL - 6, y + CELL - 12), 18, fill=NAVY)
    ic = icons[n].resize((150, 150), Image.LANCZOS)
    sheet.paste(ic, (x + (CELL - 150) // 2, y + 18), ic)
    d.text((x + CELL // 2, y + CELL - 4), n, fill=(200, 210, 235), font=font(16), anchor="mt")
y0 += secA + 10
d.text((PAD, y0), "On candy-button tiles (intel 2 recipe)", fill="white", font=font(24))
y0 += 40
for i, n in enumerate(ORDER):
    x, y = PAD + (i % COLS) * CELL, y0 + (i // COLS) * (CELL + 28)
    tile = candy_tile(170, *CANDY[i % len(CANDY)])
    ic = icons[n].resize((136, 136), Image.LANCZOS)
    tile.paste(ic, (17, 10), ic)
    sheet.paste(tile, (x + 15, y), tile)
    d.text((x + CELL // 2, y + CELL - 4), n, fill=(200, 210, 235), font=font(16), anchor="mt")
y0 += secB + 10
d.text((PAD, y0), "Actual phone size: 56 px tiles (icon ~80 %)", fill="white", font=font(24))
y0 += 44
for i, n in enumerate(ORDER):
    tile = candy_tile(56, *CANDY[i % len(CANDY)])
    ic = icons[n].resize((45, 45), Image.LANCZOS)
    tile.paste(ic, (5, 2), ic)
    sheet.paste(tile, (PAD + i * 66, y0), tile)
sheet.save(os.path.join(HERE, "contact-sheet.png"))
print("ok", sheet.size)
