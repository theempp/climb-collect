"""Zone-1 creature colour sampler (M8 prep).
  python art/tools/sample_creatures.py
Samples the r2-zone1-taiga sheet (1344x752). Each token is a luminance percentile of the creature pixels
inside the named box. Boxes marked "edge" overlap the panel, so pixels within BG_DIST of the panel background
(median of the species' bg box) are dropped there; interior boxes keep every pixel (light coats sit close to
the panel colour). Optional hue filters isolate antler/horn (unblue), gold bells and leather straps.
Writes art/creatures/creature_tokens.json (token -> hex + trace)."""
import json, os
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHEET = os.path.join(ROOT, "concepts", "2026-10-29", "r2-zone1-taiga.png")
OUT = os.path.join(ROOT, "art", "creatures", "creature_tokens.json")
BG_DIST = 28.0

BG = {"elk": (380, 170, 420, 190), "reindeer": (820, 170, 860, 190), "muskox": (1250, 180, 1290, 200),
      "hare": (520, 520, 560, 540), "boar": (980, 520, 1020, 540)}


def gold(p):  # bells: warm, yellow-dominant
    return (p[:, 0] > 140) & (p[:, 1] > 95) & (p[:, 2] < p[:, 1] - 35)


def unblue(p):  # antler/horn/tusk vs the blue-grey panel (panel B-R = 27): keep pixels with B-R < 18
    return (p[:, 2] - p[:, 0]) < 18


def leather(p):  # straps/saddle: brown, R > G > B with clear saturation
    return (p[:, 0] > p[:, 1] + 8) & (p[:, 1] > p[:, 2] + 4) & (p[:, 0] < 150)


# token: (species, box, percentile, filter, edge)
TOKENS = {
    "elk.coat_shadow": ("elk", (120, 260, 220, 305), 15, None, False),
    "elk.coat": ("elk", (120, 260, 220, 305), 50, None, False),
    "elk.coat_light": ("elk", (120, 260, 220, 305), 85, None, False),
    "elk.mane": ("elk", (245, 240, 310, 315), 70, None, False),
    "elk.mane_shadow": ("elk", (245, 240, 310, 315), 20, None, False),
    "elk.antler": ("elk", (245, 150, 370, 220), 70, unblue, True),
    "elk.leg": ("elk", (50, 340, 130, 390), 40, None, True),
    "elk.hoof": ("elk", (25, 387, 40, 405), 20, None, True),
    "elk.muzzle": ("elk", (340, 250, 365, 265), 20, None, True),
    "reindeer.coat_shadow": ("reindeer", (545, 270, 620, 320), 15, None, False),
    "reindeer.coat": ("reindeer", (545, 270, 620, 320), 50, None, False),
    "reindeer.coat_light": ("reindeer", (545, 270, 620, 320), 85, None, False),
    "reindeer.antler": ("reindeer", (710, 172, 780, 220), 50, unblue, True),
    "reindeer.leather": ("reindeer", (610, 240, 730, 330), 40, leather, True),
    "reindeer.bell": ("reindeer", (690, 237, 730, 317), 60, gold, True),
    "reindeer.hoof": ("reindeer", (480, 380, 495, 398), 20, None, True),
    "muskox.coat_shadow": ("muskox", (975, 280, 1125, 350), 15, None, False),
    "muskox.coat": ("muskox", (975, 280, 1125, 350), 50, None, False),
    "muskox.coat_light": ("muskox", (975, 280, 1125, 350), 85, None, False),
    "muskox.frost": ("muskox", (975, 245, 1125, 270), 97, None, True),
    "muskox.horn": ("muskox", (1150, 237, 1175, 275), 70, unblue, True),
    "muskox.sock": ("muskox", (915, 365, 930, 380), 70, None, True),
    "muskox.hoof": ("muskox", (965, 385, 1000, 407), 10, None, True),
    "hare.coat_shadow": ("hare", (215, 570, 290, 615), 15, None, False),
    "hare.coat": ("hare", (215, 570, 290, 615), 50, None, False),
    "hare.coat_light": ("hare", (215, 570, 290, 615), 90, None, False),
    "hare.ear_tip": ("hare", (420, 465, 435, 500), 20, None, True),
    "hare.saddle": ("hare", (285, 545, 340, 570), 50, leather, True),
    "hare.strap": ("hare", (320, 575, 345, 625), 40, leather, True),
    "hare.claw": ("hare", (420, 677, 435, 690), 15, None, True),
    "boar.coat_shadow": ("boar", (740, 560, 865, 630), 15, None, False),
    "boar.coat": ("boar", (740, 560, 865, 630), 50, None, False),
    "boar.coat_light": ("boar", (740, 560, 865, 630), 85, None, False),
    "boar.frost": ("boar", (765, 525, 880, 560), 98, None, True),
    "boar.tusk": ("boar", (920, 600, 935, 622), 70, unblue, True),
    "boar.snout": ("boar", (940, 605, 960, 620), 30, None, True),
    "boar.hoof": ("boar", (860, 677, 880, 687), 15, None, True),
    # eyes (owner 2026-10-29: dark eyes sampled per species on Z1; catchlight from Z1 frost)
    "elk.eye": ("elk", (322, 236, 334, 243), 5, None, False),
    "reindeer.eye": ("reindeer", (751, 231, 762, 239), 5, None, False),
    "muskox.eye": ("muskox", (1164, 261, 1174, 269), 5, None, False),
    "hare.eye": ("hare", (432, 522, 443, 531), 5, None, False),
    "boar.eye": ("boar", (912, 578, 921, 586), 5, None, False),
    "elk.eye_glint": ("muskox", (975, 245, 1125, 270), 97, None, True),
    "reindeer.eye_glint": ("muskox", (975, 245, 1125, 270), 97, None, True),
    "muskox.eye_glint": ("muskox", (975, 245, 1125, 270), 97, None, True),
    "hare.eye_glint": ("muskox", (975, 245, 1125, 270), 97, None, True),
    "boar.eye_glint": ("boar", (765, 525, 880, 560), 98, None, True),
}


def px(img, box):
    x0, y0, x1, y1 = box
    return img[y0:y1, x0:x1].reshape(-1, 3).astype(float)


def main():
    img = np.asarray(Image.open(SHEET).convert("RGB"))
    assert img.shape[:2] == (752, 1344), img.shape
    out = {}
    for tok, (sp, box, pct, filt, edge) in TOKENS.items():
        bg = np.median(px(img, BG[sp]), axis=0)
        p = px(img, box)
        if edge:
            p = p[np.linalg.norm(p - bg, axis=1) > BG_DIST]
        if filt is not None:
            p = p[filt(p)]
        assert len(p) >= 12, (tok, len(p))
        lum = p @ np.array([0.2126, 0.7152, 0.0722])
        cut = np.percentile(lum, pct)
        near = p[np.abs(lum - cut) <= max(2.0, np.std(lum) * 0.1)]
        rgb = np.median(near, axis=0).round().astype(int)
        trace = "Z1 (%d,%d)-(%d,%d) p%d" % (*box, pct) + (" " + filt.__name__ if filt else "") + (" bg-masked" if edge else "")
        out[tok] = {"hex": "#%02X%02X%02X" % tuple(rgb), "trace": trace, "n": int(len(p))}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        json.dump(out, f, indent=1)
    for k, v in out.items():
        print(k, v["hex"], v["n"])


if __name__ == "__main__":
    main()
