"""Render the Glassbloom white PNG masters (intel §5: U1-U6, U8-U11; U7 held).

python tools/render_glassbloom_masters.py [outdir]   (default design/glassbloom-masters)
Shapes are white; alpha carries the shape. Edges are 4x supersampled.
"""
import math, os, sys
import numpy as np
from PIL import Image

SS = 4
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '..', 'design', 'glassbloom-masters')


def grid(w, h, ss=SS):
    ys, xs = np.mgrid[0:h * ss, 0:w * ss]
    return (xs + .5) / ss, (ys + .5) / ss


def down(a, w, h, ss=SS):
    return a.reshape(h, ss, w, ss).mean(axis=(1, 3))


def save(name, alpha):
    a = np.clip(alpha, 0, 1)
    img = np.zeros(a.shape + (4,), np.uint8)
    img[..., :3] = 255
    img[..., 3] = np.round(a * 255).astype(np.uint8)
    Image.fromarray(img, 'RGBA').save(os.path.join(OUT, name + '.png'))
    print(name, a.shape[1], 'x', a.shape[0])


def rrect_inside(x, y, w, h, tl, tr, br, bl, inset=0.0):
    """True where (x,y) lies inside the rounded rect [inset, w-inset] with per-corner radii (shrunk by inset)."""
    x0, y0, x1, y1 = inset, inset, w - inset, h - inset
    inside = (x >= x0) & (x <= x1) & (y >= y0) & (y <= y1)
    for r, cx, cy, sx, sy in ((tl, x0, y0, 1, 1), (tr, x1, y0, -1, 1), (br, x1, y1, -1, -1), (bl, x0, y1, 1, -1)):
        r = max(r - inset, 0)
        if r <= 0:
            continue
        ccx, ccy = cx + sx * r, cy + sy * r
        corner = ((x - ccx) * sx < 0) & ((y - ccy) * sy < 0)
        inside &= ~(corner & ((x - ccx) ** 2 + (y - ccy) ** 2 > r * r))
    return inside


def shape(w, h, f):
    x, y = grid(w, h)
    return down(f(x, y).astype(float), w, h)


def main():
    os.makedirs(OUT, exist_ok=True)
    erfc = np.vectorize(math.erfc)

    # U1 glow: hollow outer-only Gaussian edge, .5 at r 32, ~.02 at r 64.
    x, y = grid(128, 128, 1)
    r = np.hypot(x - 64, y - 64)
    save('U1_glow', np.where(r < 32, 0, .5 * erfc((r - 32) / (16 * math.sqrt(2)))))

    # U2 rays: 20 wedges, 8 deg on / 10 deg off; opaque to r .141*R, 0 at .919*R.
    n = 512
    x, y = grid(n, n)
    R = n / 2
    ang = (np.degrees(np.arctan2(y - R, x - R)) + 360) % 18
    rr = np.hypot(x - R, y - R) / R
    fade = np.clip((.919 - rr) / (.919 - .141), 0, 1)
    save('U2_rays', down((ang < 8).astype(float) * fade, n, n))

    # U3 shield fill (TL/TR 40, BL/BR 100) and U9 outline (stroke 6).
    sh = dict(tl=40, tr=40, br=100, bl=100)
    save('U3_shield_fill', shape(256, 256, lambda x, y: rrect_inside(x, y, 256, 256, **sh)))
    save('U9_shield_line', shape(256, 256, lambda x, y: rrect_inside(x, y, 256, 256, **sh) & ~rrect_inside(x, y, 256, 256, inset=6, **sh)))

    # U4 round-top fill (TL/TR 120, BL/BR 36) and U9b outline (stroke 3).
    rt = dict(tl=120, tr=120, br=36, bl=36)
    save('U4_roundtop_fill', shape(256, 256, lambda x, y: rrect_inside(x, y, 256, 256, **rt)))
    save('U9b_roundtop_line', shape(256, 256, lambda x, y: rrect_inside(x, y, 256, 256, **rt) & ~rrect_inside(x, y, 256, 256, inset=3, **rt)))

    # U5 ticket fill: r 28, half-circle notches r 18 on the left/right edge midpoints. U10: inset ring 4 cut by the notches.
    def notch(x, y):
        return ((x - 0) ** 2 + (y - 74) ** 2 < 18 * 18) | ((x - 128) ** 2 + (y - 74) ** 2 < 18 * 18)
    tk = dict(tl=28, tr=28, br=28, bl=28)
    save('U5_ticket_fill', shape(128, 148, lambda x, y: rrect_inside(x, y, 128, 148, **tk) & ~notch(x, y)))
    save('U10_ticket_line', shape(128, 148, lambda x, y: rrect_inside(x, y, 128, 148, **tk) & ~rrect_inside(x, y, 128, 148, inset=4, **tk) & ~notch(x, y)))

    # U6 ribbon tail: polygon (0,0),(48,0),(48,60),(0,60),(20,30) -> rect minus the left notch triangle.
    def tail(x, y):
        inside = (x >= 0) & (x <= 48) & (y >= 0) & (y <= 60)
        # notch triangle (0,0)-(20,30)-(0,60): x < 20*(1-|y-30|/30)
        return inside & ~(x < 20 * (1 - np.abs(y - 30) / 30))
    save('U6_ribbon_tail', shape(48, 60, tail))

    # U8 gloss: radial centre (50%,28%), linear 1 -> 0 at .456d, clipped to the circle, peak alpha 1.
    x, y = grid(128, 128)
    g = np.clip(1 - np.hypot(x - 64, y - .28 * 128) / (.456 * 128), 0, 1)
    save('U8_gloss_orb', down(g * (np.hypot(x - 64, y - 64) <= 64), 128, 128))

    # U11 radial: alpha linear 1 at the centre -> 0 at r 64.
    x, y = grid(128, 128, 1)
    save('U11_radial', np.clip(1 - np.hypot(x - 64, y - 64) / 64, 0, 1))


if __name__ == '__main__':
    main()
