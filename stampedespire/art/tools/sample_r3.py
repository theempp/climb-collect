"""Sample the LOOKDEV tokens for the approved r3 biome sheets (2688x1520). Run from repo root:
  python -I art/tools/sample_r3.py
Same method as sample_refs.py: pct = mean of pixels within +/-5 luminance-percentile of p in the box;
hue = median of pixels matching a colour filter. "m" = bg-masked: pixels within BG_DIST of the species
panel background (median of that panel's empty box) are dropped first (edge boxes: antlers, horns, tails).
Prints token -> hex; writes art/palette_r3.json (token -> [hex, trace])."""
import json
import numpy as np
from PIL import Image

D = "concepts/2026-10-29-r3biomes/"
S = {"S2": "r3-s2-rime-fog-forest.png", "S4": "r3-s4-ice-cave-labyrinth.png", "S5": "r3-s5-hot-spring-terraces.png",
     "S7": "r3-s7-storm-peaks.png", "S8": "r3-s8-wind-carved-spires.png", "S9": "r3-s9-cloud-sea-ridge.png"}
PANEL_X = [0, 540, 1080, 1610, 2140]  # species panel left edges; empty bg box = (x0+20,470)-(x0+60,510)
BG_DIST = 28.0
_C = {}


def px(s, box):
    if s not in _C:
        _C[s] = np.asarray(Image.open(D + S[s]).convert("RGB")).astype(float)
    x0, y0, x1, y1 = box
    return _C[s][y0:y1, x0:x1].reshape(-1, 3)


def pick(r, p):
    lum = r @ [0.299, 0.587, 0.114]
    idx = np.argsort(lum)
    lo = lum[idx[max(0, int(len(idx) * (p - 5) / 100))]]
    hi = lum[idx[min(len(idx) - 1, int(len(idx) * (p + 5) / 100))]]
    return r[(lum >= lo) & (lum <= hi)].mean(0)


def mask(s, r, panel):
    x0 = PANEL_X[panel]
    bg = np.median(px(s, (x0 + 20, 470, x0 + 60, 510)), 0)
    return r[np.linalg.norm(r - bg, axis=1) > BG_DIST]


FILT = {
    "cyan": lambda R, G, B: (G > 170) & (B > 200) & (R < 150),
    "green": lambda R, G, B: (G > 140) & (G > R + 50) & (G >= B - 10),
    "warm": lambda R, G, B: (R > G + 25) & (G > B + 15) & (R > 120),
    "gold": lambda R, G, B: (R > 170) & (G > 130) & (B < G - 25),
    "violet": lambda R, G, B: (B > 180) & (R > G + 5) & (B > R + 15),
    "pale": lambda R, G, B: (B > 200) & (R > 150),
    "bright": lambda R, G, B: (R + G + B) > 690,
    "unblue": lambda R, G, B: (B - R) < 18,
    "rust": lambda R, G, B: (R > G + 25) & (G > B - 5),
}

# token: (sheet, box, kind, arg[, panel])  kind: p = percentile, h = hue filter, mp = masked percentile,
# mh = masked hue filter, hp = hue filter then percentile (arg = (filter, p))
T = {
    # --- S2 Rime Fog Forest
    "s2.sky_fog": ("S2", (1400, 0, 1600, 60), "p", 50),
    "s2.fog_glow": ("S2", (1400, 0, 1600, 150), "p", 95),
    "s2.horizon_fog": ("S2", (1360, 120, 1480, 200), "p", 50),
    "s2.far_trees": ("S2", (1580, 30, 1740, 140), "p", 25),
    "s2.birch_bark": ("S2", (935, 40, 965, 250), "p", 85),
    "s2.birch_mark": ("S2", (935, 40, 965, 250), "p", 8),
    "s2.rime_lit": ("S2", (2000, 160, 2150, 300), "p", 90),
    "s2.rime_shadow": ("S2", (2000, 160, 2150, 300), "p", 30),
    "s2.snow_lit": ("S2", (1380, 240, 1560, 320), "p", 70),
    "s2.snow_mid": ("S2", (1350, 200, 1600, 330), "p", 50),
    "s2.snow_shadow": ("S2", (1350, 200, 1600, 330), "p", 15),
    "s2.rock": ("S2", (1640, 250, 1760, 320), "p", 40),
    "s2.rock_dark": ("S2", (1640, 250, 1760, 320), "p", 8),
    "s2.title_fill": ("S2", (100, 115, 790, 235), "h", "pale"),
    "s2.title_shadow": ("S2", (100, 115, 790, 235), "p", 3),
    "s2.stag": ("S2", (160, 620, 320, 700), "p", 50),
    "s2.stag_antler": ("S2", (170, 380, 500, 530), "mp", 70, 0),
    "s2.llama": ("S2", (650, 640, 850, 720), "p", 50),
    "s2.wolf": ("S2", (1200, 600, 1380, 700), "p", 50),
    "s2.bison": ("S2", (1720, 600, 1900, 720), "p", 50),
    "s2.bison_horn": ("S2", (2075, 540, 2110, 600), "mp", 30, 3),
    "s2.fox": ("S2", (2320, 650, 2480, 730), "p", 50),
    # --- S4 Ice Cave Labyrinth
    "s4.cave_mouth": ("S4", (1300, 40, 1420, 140), "p", 80),
    "s4.cave_haze": ("S4", (1360, 0, 1560, 60), "p", 50),
    "s4.ice_wall": ("S4", (1500, 60, 1640, 140), "p", 50),
    "s4.ice_deep": ("S4", (2250, 0, 2600, 90), "p", 30),
    "s4.ice_glow": ("S4", (2060, 120, 2140, 240), "h", "cyan"),
    "s4.ice_glint": ("S4", (2060, 120, 2140, 240), "p", 97),
    "s4.moss_glow": ("S4", (950, 220, 1080, 290), "h", "green"),
    "s4.ice_shelf": ("S4", (1400, 160, 1600, 220), "p", 50),
    "s4.floor_lit": ("S4", (1400, 250, 1700, 330), "p", 80),
    "s4.floor_mid": ("S4", (1400, 250, 1700, 330), "p", 50),
    "s4.floor_shadow": ("S4", (1400, 250, 1700, 330), "p", 15),
    "s4.rock_dark": ("S4", (1960, 250, 2150, 320), "p", 10),
    "s4.title_fill": ("S4", (100, 120, 850, 240), "h", "pale"),
    "s4.title_shadow": ("S4", (100, 120, 850, 240), "p", 3),
    "s4.elk": ("S4", (140, 620, 300, 700), "p", 50),
    "s4.elk_antler": ("S4", (160, 380, 500, 560), "mh", "cyan", 0),
    "s4.bear": ("S4", (680, 620, 880, 740), "p", 50),
    "s4.armadillo": ("S4", (1250, 700, 1450, 780), "p", 50),
    "s4.armadillo_shards": ("S4", (1150, 560, 1450, 660), "mh", "cyan", 2),
    "s4.lynx": ("S4", (1760, 640, 1940, 720), "p", 50),
    "s4.lynx_tail": ("S4", (1630, 640, 1710, 740), "mh", "cyan", 3),
    "s4.tapir": ("S4", (2420, 560, 2520, 640), "p", 50),
    "s4.tapir_fringe": ("S4", (2280, 600, 2480, 700), "p", 85),
    # --- S5 Hot Spring Terraces
    "s5.sky": ("S5", (1650, 0, 1760, 40), "p", 50),
    "s5.sun_glow": ("S5", (1900, 0, 2060, 60), "p", 95),
    "s5.steam": ("S5", (1400, 60, 1520, 140), "p", 70),
    "s5.far_mountain": ("S5", (2150, 30, 2300, 90), "p", 60),
    "s5.far_forest": ("S5", (2150, 120, 2340, 200), "p", 30),
    "s5.travertine": ("S5", (900, 60, 1250, 200), "p", 85),
    "s5.travertine_mineral": ("S5", (900, 60, 1250, 200), "h", "warm"),
    "s5.pool": ("S5", (1000, 220, 1300, 290), "p", 50),
    "s5.pool_deep": ("S5", (1000, 220, 1300, 290), "p", 15),
    "s5.snow_lit": ("S5", (1680, 220, 2080, 250), "p", 80),
    "s5.snow_mid": ("S5", (1680, 220, 2080, 250), "p", 50),
    "s5.snow_shadow": ("S5", (1680, 220, 2080, 250), "p", 15),
    "s5.pine_dark": ("S5", (600, 0, 700, 80), "p", 10),
    "s5.title_fill": ("S5", (65, 120, 855, 235), "h", "pale"),
    "s5.title_shadow": ("S5", (65, 120, 855, 235), "p", 3),
    "s5.buffalo": ("S5", (110, 600, 290, 720), "p", 50),
    "s5.buffalo_horn": ("S5", (450, 520, 510, 600), "mh", "unblue", 0),
    "s5.capybara": ("S5", (660, 620, 900, 740), "p", 50),
    "s5.goat": ("S5", (1150, 640, 1300, 730), "p", 50),
    "s5.goat_horn": ("S5", (1360, 450, 1520, 540), "mh", "warm", 2),
    "s5.antelope": ("S5", (1740, 620, 1940, 700), "p", 50),
    "s5.antelope_horn": ("S5", (1960, 460, 2080, 540), "mh", "unblue", 3),
    "s5.boar": ("S5", (2220, 620, 2460, 720), "p", 50),
    # --- S7 Storm Peaks
    "s7.sky_storm": ("S7", (2000, 0, 2250, 80), "p", 30),
    "s7.sky_cloud": ("S7", (1950, 90, 2100, 180), "p", 60),
    "s7.lightning_core": ("S7", (1020, 0, 1090, 130), "h", "bright"),
    "s7.lightning_glow": ("S7", (950, 0, 1150, 200), "h", "violet"),
    "s7.storm_haze": ("S7", (1200, 40, 1340, 100), "p", 50),
    "s7.far_peaks": ("S7", (2250, 230, 2450, 300), "p", 50),
    "s7.storm_rock_lit": ("S7", (1100, 150, 1250, 280), "p", 70),
    "s7.storm_rock": ("S7", (1100, 150, 1250, 280), "p", 10),
    "s7.snow_lit": ("S7", (1400, 240, 1600, 320), "p", 80),
    "s7.snow_mid": ("S7", (1400, 240, 1600, 320), "p", 50),
    "s7.snow_shadow": ("S7", (1400, 240, 1600, 320), "p", 15),
    "s7.title_fill": ("S7", (110, 115, 700, 245), "h", "pale"),
    "s7.title_shadow": ("S7", (110, 115, 700, 245), "p", 3),
    "s7.yak": ("S7", (100, 620, 280, 720), "p", 50),
    "s7.yak_horn": ("S7", (500, 500, 550, 600), "mp", 60, 0),
    "s7.stallion": ("S7", (720, 610, 880, 690), "p", 50),
    "s7.gazelle": ("S7", (1200, 620, 1400, 700), "p", 50),
    "s7.gazelle_horn": ("S7", (1340, 460, 1470, 540), "mh", "violet", 2),
    "s7.rhino": ("S7", (1720, 600, 1920, 720), "p", 50),
    "s7.rhino_horn": ("S7", (2000, 560, 2070, 680), "mh", "violet", 3),
    "s7.wolf": ("S7", (2260, 620, 2460, 700), "p", 50),
    # --- S8 Wind-Carved Spires
    "s8.sky_top": ("S8", (1650, 0, 1780, 60), "p", 50),
    "s8.sky_horizon": ("S8", (2020, 130, 2120, 180), "p", 50),
    "s8.wind_streak": ("S8", (2000, 40, 2100, 100), "p", 90),
    "s8.spire_lit": ("S8", (830, 100, 1000, 300), "hp", ("rust", 85)),
    "s8.spire_rust": ("S8", (830, 100, 1000, 300), "hp", ("rust", 50)),
    "s8.spire_shadow": ("S8", (830, 100, 1000, 300), "hp", ("rust", 15)),
    "s8.spire_dark": ("S8", (830, 100, 1000, 300), "p", 3),
    "s8.far_spires": ("S8", (1670, 190, 1720, 240), "p", 50),
    "s8.snow_lit": ("S8", (2050, 280, 2250, 330), "p", 80),
    "s8.snow_mid": ("S8", (2050, 280, 2250, 330), "p", 50),
    "s8.snow_shadow": ("S8", (2050, 280, 2250, 330), "p", 15),
    "s8.title_fill": ("S8", (40, 115, 900, 225), "h", "pale"),
    "s8.title_shadow": ("S8", (40, 115, 900, 225), "p", 3),
    "s8.pronghorn": ("S8", (170, 600, 300, 650), "h", "warm"),
    "s8.pronghorn_horn": ("S8", (380, 400, 470, 500), "mp", 30, 0),
    "s8.markhor": ("S8", (680, 610, 880, 690), "p", 50),
    "s8.markhor_horn": ("S8", (840, 400, 980, 520), "mp", 40, 1),
    "s8.camel": ("S8", (1180, 620, 1380, 720), "p", 50),
    "s8.leopard": ("S8", (1800, 620, 1980, 700), "p", 60),
    "s8.oryx": ("S8", (2240, 600, 2420, 680), "p", 50),
    "s8.oryx_horn": ("S8", (2380, 420, 2480, 540), "mp", 20, 4),
    # --- S9 Cloud Sea Ridge
    "s9.sky_zenith": ("S9", (900, 0, 1100, 30), "p", 50),
    "s9.sky_warm": ("S9", (1500, 0, 1700, 30), "p", 50),
    "s9.sky_horizon": ("S9", (1600, 70, 1800, 100), "p", 50),
    "s9.sun_core": ("S9", (2100, 40, 2170, 90), "p", 97),
    "s9.sun_glow": ("S9", (1950, 0, 2300, 100), "p", 70),
    "s9.cloud_lit": ("S9", (900, 150, 1300, 320), "p", 85),
    "s9.cloud_mid": ("S9", (900, 150, 1300, 320), "p", 50),
    "s9.cloud_shadow": ("S9", (900, 150, 1300, 320), "p", 15),
    "s9.far_peak": ("S9", (1170, 60, 1270, 110), "p", 50),
    "s9.snow_lit": ("S9", (1960, 240, 2150, 320), "p", 80),
    "s9.snow_shadow": ("S9", (1960, 240, 2150, 320), "p", 15),
    "s9.rock": ("S9", (1720, 240, 1800, 310), "p", 30),
    "s9.title_fill": ("S9", (75, 110, 835, 220), "h", "pale"),
    "s9.title_shadow": ("S9", (75, 110, 835, 220), "p", 3),
    "s9.ostrich": ("S9", (120, 590, 320, 680), "p", 50),
    "s9.horse": ("S9", (700, 620, 880, 700), "p", 50),
    "s9.deer": ("S9", (1160, 620, 1360, 700), "p", 50),
    "s9.deer_antler": ("S9", (1360, 450, 1500, 530), "mh", "gold", 2),
    "s9.sheep": ("S9", (1700, 580, 1950, 720), "p", 50),
    "s9.sheep_horn": ("S9", (1885, 530, 1945, 600), "mp", 40, 3),
    "s9.kudu": ("S9", (2260, 600, 2420, 680), "p", 50),
    "s9.kudu_horn": ("S9", (2380, 380, 2520, 500), "mp", 50, 4),
}


def sample(t):
    s, box, kind, arg = t[:4]
    r = px(s, box)
    if kind[0] == "m":
        r = mask(s, r, t[4])
    if kind == "hp":
        r = r[FILT[arg[0]](r[:, 0], r[:, 1], r[:, 2])]
        v = pick(r, arg[1])
    elif kind[-1] == "h":
        r = r[FILT[arg](r[:, 0], r[:, 1], r[:, 2])]
        v = np.median(r, 0)
    else:
        v = pick(r, arg)
    return "#%02X%02X%02X" % tuple(v.round().astype(int)), len(r)


if __name__ == "__main__":
    out = {}
    for k, t in T.items():
        hx, n = sample(t)
        b = t[1]
        if t[2] == "hp":
            how = "%s pixels p%d" % t[3]
        else:
            how = ("bg-masked " if t[2][0] == "m" else "") + (("%s median" % t[3]) if t[2][-1] == "h" else "p%d" % t[3])
        out[k] = [hx, "%s (%d,%d)-(%d,%d) %s" % (t[0], *b, how)]
        print("%-24s %s  n=%-6d %s" % (k, hx, n, out[k][1]))
    json.dump(out, open("art/palette_r3.json", "w"), indent=1)
