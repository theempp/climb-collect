"""Re-sample the LOOKDEV palette from the approved r2 sheets. Run from repo root: python art/tools/sample_refs.py"""
from PIL import Image
import numpy as np
D = "concepts/2026-10-29/"

def pct(f, box, p):  # mean of pixels within +/-5 luminance-percentile of p
    a = np.asarray(Image.open(D + f).convert("RGB")).astype(float)
    x0, y0, x1, y1 = box
    r = a[y0:y1, x0:x1].reshape(-1, 3)
    lum = r @ [0.299, 0.587, 0.114]
    idx = np.argsort(lum)
    lo = lum[idx[max(0, int(len(idx) * (p - 5) / 100))]]
    hi = lum[idx[min(len(idx) - 1, int(len(idx) * (p + 5) / 100))]]
    return r[(lum >= lo) & (lum <= hi)].mean(0).round().astype(int)

def hue(f, box, cond):  # median of pixels matching cond(R,G,B)
    a = np.asarray(Image.open(D + f).convert("RGB")).astype(float)
    x0, y0, x1, y1 = box
    r = a[y0:y1, x0:x1].reshape(-1, 3)
    return np.median(r[cond(r[:, 0], r[:, 1], r[:, 2])], 0).round().astype(int)

Z1, Z2, Z3, Z4 = "r2-zone1-taiga.png", "r2-zone2-crevasse.png", "r2-zone3-obsidian.png", "r2-zone4-aurora.png"
RR, RP = "r2-rider-roblox.png", "r2-replacements-saiga-ashmane.png"
P = {
    "z1.sky_top": pct(Z1, (700, 2, 780, 15), 50), "z1.sky_horizon": pct(Z1, (760, 40, 800, 48), 50),
    "z1.sun_glow": pct(Z1, (900, 8, 930, 20), 50), "z1.far_mountain": pct(Z1, (740, 30, 770, 38), 50),
    "z1.far_treeline": pct(Z1, (720, 55, 770, 65), 50), "z1.pine_dark": pct(Z1, (600, 30, 640, 90), 10),
    "z1.pine_mid": pct(Z1, (600, 30, 640, 90), 35), "z1.pine_snow": pct(Z1, (600, 30, 640, 90), 92),
    "z1.snow_lit": pct(Z1, (850, 105, 900, 120), 70), "z1.snow_mid": pct(Z1, (700, 100, 900, 122), 50),
    "z1.snow_shadow": pct(Z1, (700, 100, 760, 122), 15), "z1.river_ice": pct(Z1, (770, 85, 820, 92), 50),
    "z1.rock": pct(Z1, (1050, 100, 1100, 118), 8), "z1.rock_warm": pct(RR, (0, 300, 440, 440), 4),
    "z2.ice_deep": pct(Z2, (420, 60, 440, 140), 10), "z2.ice_mid": pct(Z2, (520, 40, 560, 120), 50),
    "z2.ice_hi": pct(Z2, (520, 40, 560, 120), 95), "z2.shaft": pct(Z2, (690, 5, 710, 30), 50),
    "z2.canyon_far": pct(Z2, (660, 60, 690, 100), 50), "z2.floor_snow": pct(Z2, (650, 150, 720, 165), 60),
    "z2.bridge": pct(Z2, (670, 135, 700, 145), 50), "z2.rock_ledge": pct(Z2, (850, 110, 950, 160), 50),
    "z2.shadow": pct(Z2, (400, 130, 420, 165), 20), "z2.ground_snow": pct(RP, (100, 430, 300, 470), 60),
    "z2.cliff": pct(RP, (0, 100, 120, 300), 50),
    "z3.sky_upper": pct(Z3, (470, 0, 560, 30), 50), "z3.sky_haze": pct(Z3, (760, 20, 790, 30), 50),
    "z3.sky_sun": hue(Z3, (880, 5, 1000, 40), lambda R, G, B: R > 150), "z3.sky_glow": pct(Z3, (930, 20, 960, 35), 50),
    "z3.spire_dark": pct(Z3, (620, 30, 660, 70), 10), "z3.rock_lit": pct(Z3, (590, 40, 650, 90), 75),
    "z3.far_ridge": pct(Z3, (830, 50, 870, 70), 50), "z3.ground": pct(Z3, (800, 105, 880, 120), 40),
    "z3.lava_deep": hue(Z3, (560, 60, 660, 115), lambda R, G, B: (R > 120) & (R < 200) & (G < 80)),
    "z3.lava_orange": hue(Z3, (560, 60, 660, 115), lambda R, G, B: (R > 200) & (G > 80) & (G < 170)),
    "z3.lava_hot": hue(Z3, (560, 60, 660, 115), lambda R, G, B: (R > 230) & (G > 170)),
    "z3.steam": pct(Z3, (725, 30, 740, 60), 60), "z3.ash_ground": pct(RP, (700, 400, 800, 470), 50),
    "z4.night_deep": hue(Z4, (400, 0, 1190, 178), lambda R, G, B: (R + G + B) < 90),
    "z4.sky_navy": pct(Z4, (620, 5, 860, 60), 5),
    "z4.aurora_green": hue(Z4, (600, 0, 800, 60), lambda R, G, B: (G > 150) & (G > R + 40)),
    "z4.aurora_teal": pct(Z4, (1000, 10, 1030, 40), 60),
    "z4.aurora_purple": hue(Z4, (850, 0, 1000, 70), lambda R, G, B: (R > B * 0.55) & (R > G) & (B > 100)),
    "z4.crystal_glint": hue(Z4, (490, 10, 530, 110), lambda R, G, B: (R + G + B) > 600),
    "z4.crystal_light": hue(Z4, (490, 10, 530, 110), lambda R, G, B: ((R + G + B) > 350) & ((R + G + B) < 600)),
    "z4.crystal_mid": pct(Z4, (440, 90, 470, 130), 50), "z4.crystal_deep": pct(Z4, (430, 80, 500, 150), 10),
    "z4.rock_spire": pct(Z4, (870, 90, 900, 130), 40), "z4.far_mountains": pct(Z4, (600, 80, 640, 95), 50),
    "z4.snow_path": pct(Z4, (960, 130, 1000, 150), 60), "z4.snow_shadow": pct(Z4, (1100, 140, 1150, 160), 40),
    # Z4 sky gradient (M6 skybox): blue-dominant (non-aurora, non-crystal) sky pixels, left of the crystals
    "z4.sky_zenith": hue(Z4, (400, 0, 600, 10), lambda R, G, B: (B > G + 10) & (B > R + 10) & (R + G + B < 420)),
    "z4.sky_mid": hue(Z4, (400, 30, 600, 40), lambda R, G, B: (B > G + 10) & (B > R + 10) & (R + G + B < 420)),
    "z4.sky_low": hue(Z4, (400, 50, 600, 60), lambda R, G, B: (B > G + 10) & (B > R + 10) & (R + G + B < 420)),
}
if __name__ == "__main__":
    import json
    out = {k: "#%02X%02X%02X" % tuple(v) for k, v in P.items()}
    print(json.dumps(out, indent=1))
    json.dump(out, open("art/palette.json", "w"), indent=1)
