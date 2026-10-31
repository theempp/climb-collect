#!/usr/bin/env python3
"""P4 fog / visible-distance measurement for Stampede Spire (Sections place, Play Solo, phone simulator).

1. capture: start this, then run `require(game.ReplicatedStorage.SS_Bot)("fog")` in the Client command bar.
   Grabs the Studio window as fast as it can, finds the magenta corner squares and the code square drawn by
   SS_Bot's fog mode, and keeps the last frame of every (section, distance, shown/hidden) state as a PNG of the
   viewport. Logs the foreground window's PID once a second, and marks every kept state with whether Studio
   was the foreground window for all of it: a background Studio throttles and draws less far (the first P4
   capture lost the foreground and read 0% from 500 studs on), so analyse rejects those frames.
       python fogmeasure.py capture --out DIR [--seconds 420]
2. analyse: pairs each shown frame with its hidden frame and measures what the creature adds to the image:
   peak Weber luminance contrast |L_shown - L_hidden| / L_hidden inside the model's viewport rect (FOGRECT lines
   from the Studio log). Noise floor = the same rect in two successive hidden frames of the same section.
       python fogmeasure.py analyse --dir DIR --log STUDIO_LOG [--threshold 0.05] [--min-px 4]
   A species is readable at D if contrast >= threshold, contrast >= 3x noise and its height is >= min-px device
   px. Two tables: at the held camera's FOV (Cam.Fov 66: on foot, falling, slow mounts: creatures look biggest)
   and at the tier-1 ride FOV. The section's readable distance is the largest readable D over its 5 common
   species (the most visible one decides when a pop-in can be seen).
"""
import argparse
import ctypes
import ctypes.wintypes as wt
import json
import math
import os
import re
import sys
import time

import numpy as np
from PIL import Image, ImageGrab

user32 = ctypes.windll.user32
try:
    ctypes.windll.shcore.SetProcessDpiAwareness(2)
except Exception:
    pass

NDIST = 18  # SS_Bot FogDists; code G = index x 14
CODE_G = 14


def find_window(part):
    found = []

    @ctypes.WINFUNCTYPE(wt.BOOL, wt.HWND, wt.LPARAM)
    def cb(h, _):
        n = user32.GetWindowTextLengthW(h)
        if n and user32.IsWindowVisible(h):
            buf = ctypes.create_unicode_buffer(n + 1)
            user32.GetWindowTextW(h, buf, n + 1)
            if part in buf.value and "Roblox Studio" in buf.value:
                found.append((h, buf.value))
        return True

    user32.EnumWindows(cb, 0)
    return found


def fg_info():
    h = user32.GetForegroundWindow()
    pid = wt.DWORD()
    user32.GetWindowThreadProcessId(h, ctypes.byref(pid))
    n = user32.GetWindowTextLengthW(h)
    buf = ctypes.create_unicode_buffer(n + 1)
    user32.GetWindowTextW(h, buf, n + 1)
    return pid.value, buf.value


def markers(a):
    m = (a[:, :, 0] > 235) & (a[:, :, 1] < 30) & (a[:, :, 2] > 235)
    ys, xs = np.nonzero(m)
    if len(xs) < 20:
        return None
    tl = (xs.min(), ys.min())
    br = (xs.max(), ys.max())
    if br[0] - tl[0] < 100 or br[1] - tl[1] < 100:
        return None
    side = 0  # the top-left square's size on screen
    while tl[0] + side < a.shape[1] and m[tl[1] + 1, tl[0] + side]:
        side += 1
    return tl, br, side


def frame_name(code):
    k, i, ph = code
    return f"s{k:02d}_d{i:02d}_{'on' if ph else 'off'}.png"


def capture(out, seconds, title):
    os.makedirs(out, exist_ok=True)
    wins = find_window(title)
    if not wins:
        sys.exit(f"no Studio window with '{title}' in its title")
    hwnd, wtitle = wins[0]
    pid = wt.DWORD()
    user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
    print(f"window {wtitle!r} pid {pid.value}", flush=True)
    r = wt.RECT()
    fglog = open(os.path.join(out, "foreground.log"), "w")
    last_code, last_img, last_img_t, kept, t0, next_fg, geo = None, None, 0.0, 0, time.time(), 0, None
    # fg_ok: Studio in front on every grab of the current code state (also grabs where the markers were not found);
    # the kept frame must also come SETTLE s after the last moment Studio was in the background (it renders less far
    # while throttled and needs a moment to catch up)
    SETTLE = 0.3
    fg_ok, index, last_bg = True, {}, -1e9

    def keep():
        nonlocal kept
        if last_code is not None and last_img is not None:
            name = frame_name(last_code)
            last_img.save(os.path.join(out, name))
            index[name] = fg_ok and last_img_t - last_bg >= SETTLE
            kept += 1
            json.dump(index, open(os.path.join(out, "index.json"), "w"), indent=0)  # as it goes: survives Ctrl+C

    while time.time() - t0 < seconds:
        now = time.time()
        fpid, ftitle = fg_info()
        front = fpid == pid.value
        if not front:
            last_bg = now
            fg_ok = False
        if now >= next_fg:
            fglog.write(f"{now - t0:.1f} {fpid} {'OK' if front else 'OTHER'} {ftitle}\n")
            fglog.flush()
            next_fg = now + 1
        user32.GetWindowRect(hwnd, ctypes.byref(r))
        img = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom), all_screens=True)
        a = np.asarray(img)
        mk = markers(a)
        if not mk:
            continue
        (tx, ty), (bx, by), side = mk
        s = side / 16.0
        cx, cy = int(tx + 24 * s), int(ty + 8 * s)
        c = tuple(int(v) for v in a[cy, cx, :3])
        code = (round(c[0] / 20), round(c[1] / CODE_G), 1 if c[2] > 120 else 0)
        if code[0] < 1 or code[0] > 10 or code[1] < 1 or code[1] > NDIST:
            code = None  # black between sections: not a measured state
        if code != last_code:
            keep()
            fg_ok = front
        last_code = code
        last_img = img.crop((tx, ty, bx + 1, by + 1)) if code is not None else None
        last_img_t = now
        geo = dict(tl=[int(tx), int(ty)], br=[int(bx), int(by)], side=side)
    keep()
    json.dump(geo, open(os.path.join(out, "geometry.json"), "w"))
    json.dump(index, open(os.path.join(out, "index.json"), "w"), indent=0)
    fglog.close()
    print(f"kept {kept} frames, {sum(1 for v in index.values() if not v)} with Studio not in front", flush=True)


def lum(a):
    c = a[:, :, :3].astype(np.float64) / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * lin[:, :, 0] + 0.7152 * lin[:, :, 1] + 0.0722 * lin[:, :, 2]


def analyse(d, logpath, thr, min_px):
    text = open(logpath, encoding="utf-8", errors="replace").read()
    vp = re.findall(r"FOGVP (\d+) (\d+) fovRide ([\d.,]+)", text)
    if not vp:
        sys.exit("no FOGVP line in the log")
    vw, vh = int(vp[-1][0]), int(vp[-1][1])
    fov_ride = [float(x) for x in vp[-1][2].split(",")]
    secs = {int(m[0]): (float(m[1]), float(m[2]), m[3]) for m in re.findall(r"FOGSEC (\d+) camD (-?[\d.]+) fov ([\d.]+) atm ([-\d./]+)", text)}
    rects = {}  # the last run in the log wins
    for m in re.findall(r"FOGRECT (\d+) (\d+) (\d+) (\d+) (\S+) (-?[\d.]+) (-?[\d.]+) (-?[\d.]+) (-?[\d.]+)", text):
        k, i, D, lane = map(int, m[:4])
        rects[(k, i, lane)] = (D, m[4], *map(float, m[5:]))
    ipath = os.path.join(d, "index.json")
    fgidx = json.load(open(ipath)) if os.path.exists(ipath) else {}
    rejected = 0
    out = {}
    for k in range(1, 11):
        fov_held = secs.get(k, (0, 66.0, ""))[1]
        rows = []
        for i in range(1, NDIST + 1):
            fon, foff = os.path.join(d, f"s{k:02d}_d{i:02d}_on.png"), os.path.join(d, f"s{k:02d}_d{i:02d}_off.png")
            fprev = os.path.join(d, f"s{k:02d}_d{i - 1:02d}_off.png")
            if not (os.path.exists(fon) and os.path.exists(foff)):
                continue
            if fgidx and not (fgidx.get(os.path.basename(fon)) and fgidx.get(os.path.basename(foff))):
                rejected += 1  # captured while Studio was not the foreground window
                continue
            on, off = np.asarray(Image.open(fon)), np.asarray(Image.open(foff))
            prev = np.asarray(Image.open(fprev)) if os.path.exists(fprev) else None
            Lon, Loff = lum(on), lum(off)
            Lprev = lum(prev) if prev is not None and prev.shape == off.shape else None
            sx, sy = on.shape[1] / vw, on.shape[0] / vh  # viewport px -> captured px
            for lane in range(1, 6):
                if (k, i, lane) not in rects:
                    continue
                D, name, x0, y0, x1, y1 = rects[(k, i, lane)]
                X0, Y0 = max(int(math.floor(x0 * sx)), 0), max(int(math.floor(y0 * sy)), 0)
                X1, Y1 = min(int(math.ceil(x1 * sx)), on.shape[1]), min(int(math.ceil(y1 * sy)), on.shape[0])
                if X1 <= X0 or Y1 <= Y0:
                    continue
                w = np.abs(Lon[Y0:Y1, X0:X1] - Loff[Y0:Y1, X0:X1]) / np.maximum(Loff[Y0:Y1, X0:X1], 0.005)
                noise = 0.0
                if Lprev is not None:
                    noise = float((np.abs(Loff[Y0:Y1, X0:X1] - Lprev[Y0:Y1, X0:X1]) / np.maximum(Loff[Y0:Y1, X0:X1], 0.005)).max())
                # height at the tier-1 ride camera's FOV (the held mount shows Cam.Fov)
                h_ride = (y1 - y0) * math.tan(math.radians(fov_held) / 2) / math.tan(math.radians(fov_ride[k - 1]) / 2)
                rows.append(dict(i=i, D=D, lane=lane, name=name, peak=float(w.max()), p90=float(np.percentile(w, 90)),
                                 noise=noise, h=h_ride, h_held=y1 - y0))
        out[k] = rows
    json.dump(out, open(os.path.join(d, "fog.json"), "w"), indent=1)
    if rejected:
        print(f"REJECTED {rejected} distance pairs captured while Studio was not the foreground window")
    for hk, title in (("h_held", "held camera, FOV 66 (on foot / falling / slow mounts)"), ("h", "tier-1 ride FOV")):
        print(f"\n#### Readable distance at the {title}: contrast >= {100 * thr:.0f}%, >= 3x noise, >= {min_px:g} px tall")
        print("| Sec | atm density/haze | readable distance (studs) | most visible species | peak contrast at 300 / 450 / 600 / 900 | its height (px) |")
        print("|---|---|---|---|---|---|")
        lst = []
        for k in range(1, 11):
            rows = out[k]
            best = {}
            for r in rows:
                ok = r["peak"] >= thr and r["peak"] >= 3 * r["noise"] and r[hk] >= min_px
                if ok and r["D"] > best.get(r["name"], (0,))[0]:
                    best[r["name"]] = (r["D"], r)
            far = max(best.values(), key=lambda t: t[0]) if best else (0, None)
            lst.append(far[0])

            def at(D):
                vals = [r["peak"] for r in rows if r["D"] == D]
                return f"{100 * max(vals):.0f}%" if vals else "-"
            cam = secs.get(k, ("-", "-", "-"))
            contrast = f"{at(300)} / {at(450)} / {at(600)} / {at(900)}"
            if far[1]:
                print(f"| {k} | {cam[2]} | {far[0]} | {far[1]['name']} | {contrast} | {far[1][hk]:.1f} |")
            else:
                print(f"| {k} | {cam[2]} | {'no frames' if not rows else '< 75'} | - | {contrast} | - |")
        print("as a list: " + ",".join(str(v) for v in lst))
    print("\nper-distance peak contrast, most visible species (%), and its held-FOV height (px):")
    for k in range(1, 11):
        by = {}
        for r in out[k]:
            if r["peak"] > by.get(r["D"], (0, 0))[0]:
                by[r["D"]] = (r["peak"], r["h_held"])
        print(f"s{k}: " + " ".join(f"{D}:{100 * v[0]:.0f}/{v[1]:.1f}" for D, v in sorted(by.items())))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("capture")
    c.add_argument("--out", required=True)
    c.add_argument("--seconds", type=float, default=420)
    c.add_argument("--title", default="StampedeSpire.Sections")
    a = sub.add_parser("analyse")
    a.add_argument("--dir", required=True)
    a.add_argument("--log", required=True)
    a.add_argument("--threshold", type=float, default=0.05)
    a.add_argument("--min-px", type=float, default=4.0)
    x = ap.parse_args()
    if x.cmd == "capture":
        capture(x.out, x.seconds, x.title)
    else:
        analyse(x.dir, x.log, x.threshold, x.min_px)


if __name__ == "__main__":
    main()
