"""Paints the shared palette atlas (art/export/ss_atlas.png). Every ramp stop is a LOOKDEV token
(art/palette.json, sampled from the r2 sheets). Rows are 16 px tall; U runs dark -> light."""
import json, os, random


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PAL = json.load(open(os.path.join(ROOT, "art", "palette.json")))
# r3 biome tokens (sample_r3.py stores [hex, trace]); their keys (s2.*, s4.*, ...) never clash with z1-z4
PAL.update({k: v[0] for k, v in json.load(open(os.path.join(ROOT, "art", "palette_r3.json"))).items()})
W, ROWH, NROWS = 256, 16, 32
NROWS10 = 64  # 10-section atlas (ss_atlas10.png): the 18 rows below, then RAMPS_R3

# name -> token stops (dark -> light). Order = row index; ssblend.ROWS mirrors this list.
RAMPS = [
    ("z1_snow", ["z1.snow_shadow", "z1.snow_mid", "z1.snow_lit", "z1.sun_glow"]),
    ("z1_rock", ["z1.rock_warm", "z1.rock", "z1.far_treeline"]),
    ("z1_pine", ["z1.pine_dark", "z1.pine_mid", "z1.pine_snow"]),
    ("z1_ice", ["z1.snow_shadow", "z1.river_ice", "z1.sky_top"]),
    ("z1_far", ["z1.far_treeline", "z1.far_mountain", "z1.sky_top", "z1.snow_lit"]),
    ("z2_ice", ["z2.ice_deep", "z2.ice_mid", "z2.ice_hi"]),
    ("z2_snow", ["z2.cliff", "z2.floor_snow", "z2.ground_snow", "z2.shaft"]),
    ("z2_ledge", ["z2.shadow", "z2.rock_ledge", "z2.cliff"]),
    ("z2_bridge", ["z2.ice_mid", "z2.bridge", "z2.ice_hi", "z2.shaft"]),
    ("z3_obsidian", ["z3.spire_dark", "z3.rock_lit", "z3.far_ridge"]),
    ("z3_ground", ["z3.spire_dark", "z3.far_ridge", "z3.ash_ground", "z3.ground"]),
    ("z3_lava", ["z3.lava_deep", "z3.lava_orange", "z3.lava_hot"]),
    ("z3_far", ["z3.far_ridge", "z3.sky_haze", "z3.sky_sun"]),
    ("z4_crystal", ["z4.crystal_deep", "z4.crystal_mid", "z4.crystal_light", "z4.crystal_glint"]),
    ("z4_rock", ["z4.night_deep", "z4.rock_spire", "z4.far_mountains"]),
    ("z4_snow", ["z4.rock_spire", "z4.snow_shadow", "z4.snow_path"]),
    ("z4_far", ["z4.rock_spire", "z4.far_mountains", "z4.snow_shadow"]),
    ("z4_aurora", ["z4.aurora_green", "z4.aurora_teal", "z4.aurora_purple"]),
]

# r3 biome rows (LOOKDEV sections 2/4/5/7/8/9), appended after RAMPS so z1-z4 keep their row index.
RAMPS_R3 = [
    ("s2_snow", ["s2.snow_shadow", "s2.snow_mid", "s2.snow_lit", "s2.fog_glow"]),
    ("s2_rock", ["s2.rock_dark", "s2.rock", "s2.rime_shadow"]),
    ("s2_birch", ["s2.birch_mark", "s2.birch_bark", "s2.rime_lit", "s2.snow_lit"]),
    ("s2_fir", ["s2.rock_dark", "s2.rime_shadow", "s2.rime_lit", "s2.snow_lit"]),
    ("s2_far", ["s2.far_trees", "s2.horizon_fog", "s2.sky_fog"]),
    ("s4_ice", ["s4.ice_deep", "s4.ice_wall", "s4.ice_shelf", "s4.cave_haze", "s4.cave_mouth"]),
    ("s4_floor", ["s4.floor_shadow", "s4.floor_mid", "s4.floor_lit"]),
    ("s4_rock", ["s4.ice_deep", "s4.rock_dark", "s4.ice_wall"]),
    ("s4_glow", ["s4.moss_glow", "s4.ice_glow", "s4.ice_glint"]),
    ("s4_far", ["s4.ice_deep", "s4.ice_wall", "s4.cave_haze"]),
    ("s5_trav", ["s5.travertine_mineral", "s5.travertine"]),
    ("s5_pool", ["s5.pool_deep", "s5.pool"]),
    ("s5_snow", ["s5.snow_shadow", "s5.snow_mid", "s5.snow_lit", "s5.sun_glow"]),
    ("s5_pine", ["s5.pine_dark", "s5.far_forest", "s5.snow_mid", "s5.snow_lit"]),
    ("s5_far", ["s5.far_forest", "s5.far_mountain", "s5.sky"]),
    ("s7_rock", ["s7.storm_rock", "s7.storm_haze", "s7.storm_rock_lit"]),
    ("s7_snow", ["s7.snow_shadow", "s7.snow_mid", "s7.snow_lit"]),
    ("s7_far", ["s7.far_peaks", "s7.storm_haze", "s7.sky_cloud"]),
    ("s7_bolt", ["s7.lightning_glow", "s7.lightning_core"]),
    ("s8_spire", ["s8.spire_dark", "s8.spire_shadow", "s8.spire_rust", "s8.spire_lit"]),
    ("s8_snow", ["s8.snow_shadow", "s8.snow_mid", "s8.snow_lit"]),
    ("s8_far", ["s8.far_spires", "s8.sky_horizon"]),
    ("s9_rock", ["s9.rock", "s9.snow_shadow"]),
    ("s9_snow", ["s9.snow_shadow", "s9.snow_lit"]),
    ("s9_cloud", ["s9.cloud_shadow", "s9.cloud_mid", "s9.cloud_lit"]),
    ("s9_far", ["s9.far_peak", "s9.cloud_mid", "s9.sky_horizon"]),
]
RAMPS10 = RAMPS + RAMPS_R3


def hexrgb(h):
    h = PAL[h].lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def ramp(stops, u):
    cols = [hexrgb(s) for s in stops]
    t = u * (len(cols) - 1)
    i = min(int(t), len(cols) - 2)
    f = t - i
    return [cols[i][c] + (cols[i + 1][c] - cols[i][c]) * f for c in range(3)]


def main(sections=False):
    from PIL import Image
    random.seed(7)
    ramps, nrows = (RAMPS10, NROWS10) if sections else (RAMPS, NROWS)
    assert len(ramps) <= nrows
    im = Image.new("RGB", (W, ROWH * nrows), (0, 0, 0))
    px = im.load()
    for r, (_, stops) in enumerate(ramps):
        for y in range(ROWH):
            streak = random.uniform(-0.025, 0.025)  # horizontal brush streaks, painted look
            for x in range(W):
                if x % 8 == 0:
                    streak += random.uniform(-0.01, 0.01)
                    streak = max(-0.04, min(0.04, streak))
                c = ramp(stops, x / (W - 1))
                k = 1 + streak
                px[x, r * ROWH + y] = tuple(max(0, min(255, int(round(v * k)))) for v in c)
    out = os.path.join(ROOT, "art", "export", "ss_atlas10.png" if sections else "ss_atlas.png")
    im.save(out)
    print("atlas", out, len(ramps), "ramps")


if __name__ == "__main__":
    import sys
    main("--sections" in sys.argv)
