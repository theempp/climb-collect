"""Zone-4 skybox faces from LOOKDEV tokens (z4.sky_zenith / sky_mid / sky_low), by elevation.
python art/tools/make_sky.py -> art/export/sky/z4_side.png, z4_up.png, z4_down.png (the 4 sides share one image)."""
import json, math, os
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PAL = json.load(open(os.path.join(ROOT, "art", "palette.json")))
OUT = os.path.join(ROOT, "art", "export", "sky")
N = 512
STOPS = [(0, "z4.sky_low"), (25, "z4.sky_mid"), (60, "z4.sky_zenith"), (90, "z4.sky_zenith")]  # elevation deg


def rgb(k):
    h = PAL[k].lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float)


def colour(el):
    el = np.clip(el, 0, 90)
    out = np.zeros(el.shape + (3,))
    for (e0, k0), (e1, k1) in zip(STOPS, STOPS[1:]):
        t = np.clip((el - e0) / max(e1 - e0, 1e-6), 0, 1)
        t = t * t * (3 - 2 * t)
        m = (el >= e0) & (el <= e1)
        out[m] = (rgb(k0) * (1 - t[..., None]) + rgb(k1) * t[..., None])[m]
    return out


def save(a, name):
    rng = np.random.default_rng(7)
    a = np.clip(a + rng.uniform(-0.6, 0.6, a.shape), 0, 255)  # dither against banding
    Image.fromarray(a.round().astype(np.uint8)).save(os.path.join(OUT, name))


os.makedirs(OUT, exist_ok=True)
c = (np.arange(N) + 0.5) / N * 2 - 1
u, v = np.meshgrid(c, -c)  # v = +1 at the top row
save(colour(np.degrees(np.arctan2(v, np.sqrt(u * u + 1)))), "z4_side.png")
save(colour(np.degrees(np.arctan2(1, np.sqrt(u * u + v * v)))), "z4_up.png")
save(colour(np.zeros_like(u)), "z4_down.png")
print("SKY OK", OUT)
