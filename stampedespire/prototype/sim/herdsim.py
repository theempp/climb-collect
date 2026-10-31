#!/usr/bin/env python3
"""Stampede Spire P2 herd-pool model (stdlib only, deterministic per seed).

A MODEL, NOT A PLAYTEST. 1D-per-lane kinematics of the P2 rider-relative herd pool along the 17,960-stud
path, mirroring the algorithm in src/SS_Ride.client.luau ("Herd pool", lines ~866-1110, and the lane
solver at ~1140-1227) with the values from src/SS_Config.luau. Every constant below cites its source line.

Usage:
  python herdsim.py run [--policy normal] [--per-lane 5] [--ahead 700] [--seed 1] ...
  python herdsim.py report --out results.md      # all experiments used by prototype/HERD-SIM.md
"""
import argparse
import math
import random
import statistics
import sys

# ---------------------------------------------------------------------------------------------------
# Config (src/SS_Config.luau). Zones: (name, Length, LaneWidth, Speed, Time)            SS_Config:18-27
ZONES = [
    ("Frozen Taiga Foothills", 880, 12.0, 22.0, 40),
    ("Rime Fog Forest", 1010, 11.5, 25.3, 40),
    ("Crevasse Ice Canyons", 1170, 11.0, 29.1, 40),
    ("Ice Cave Labyrinth", 1340, 10.0, 33.5, 40),
    ("Hot Spring Terraces", 1540, 9.5, 38.6, 40),
    ("Geothermal Obsidian Ridge", 1780, 8.5, 44.4, 40),
    ("Storm Peaks", 2050, 8.0, 51.2, 40),
    ("Wind-Carved Spires", 2360, 7.5, 58.9, 40),
    ("Cloud Sea Ridge", 2710, 7.0, 67.8, 40),
    ("Aurora Crown", 3120, 6.5, 78.0, 40),
]
NARROW_RAMP = 40       # SS_Config:29
LANE_COUNT = 5         # SS_Config:30
SPEED_RAMP = 40        # SS_Config:146
SPEED_JITTER = 0.1     # SS_Config:147
# Pool                                                                                   SS_Config:160-161
POOL = dict(Behind=150, Ahead=700, FrontBand=250, ViewDist=300, PerLane=5, ExtraEach=2, SpawnPerFrame=4,
            Tries=8, FadeIn=1.0)
RECYCLE_AHEAD, RECYCLE_CLEAR, LANE_GAP = 250, 120, 14   # SS_Config:163 (P2 values; src now: per section, see P4)
# P4 fog table (TEST-LOG "P4 fog", owner: readable = >= 4 px on the phone): SS_Config Pool.ViewDist and
# RecycleAhead per section, Pool.Ahead 500, no FrontBand (respawns ahead anywhere past ViewDist). The `ten-d`
# command uses these by default; pass --view-dist-sec / --recycle-ahead-sec / --ahead to compare.
P4_VIEW = [350.0] * 10  # spawn distance ahead (P4 re-measure: readability is handled by FarFade, see P4_READ)
P4_AHEAD = 420  # SS_Config Pool.Ahead (500 -> 420 after the leaving fix, P4 re-review)
# P4 fog re-measure (real models, Studio in front; tier-1 ride FOV, >= 4 px, >= 5% contrast): readable distance
P4_READ = [700.0, 600.0, 600.0, 600.0, 550.0, 550.0, 550.0, 550.0, 450.0, 500.0]
P4_FAR_FADE = 2.0  # SS_Config Pool.FarFade (3 s kept up to 62 live vs the 10d cap 60 in 2/48 runs)
SRC_HERD = [8, 7, 6, 6, 6, 6, 6, 6, 5, 5]  # SS_Config Zones[k].Herd (P4 pace: s5-s10 +1)
PASS_RETRY, PASS_EASE = 0.6, 2.5                         # SS_Config:164
SUMMIT_FADE = 40                                         # SS_Config:165
SWAP_RANGE = 40                                          # SS_Config:191
STANCE_TIME = 0.6                                        # SS_Config:193
RING_DURATION, RING_START, TARGET_SCALE = 1.4, 3, 1     # SS_Config:196-198
IDEAL_PRESS = RING_DURATION * (RING_START - TARGET_SCALE) / RING_START  # 0.933 s, SS_Bot / SS_Ride:1446
JUMP_TIME = 0.55                                         # SS_Config:200
LEAP = dict(Time=1.1, PowerTime=0.5, Slow=0.3, EaseIn=0.15, EaseOut=0.12, MaxSlow=1.4)  # SS_Config:206-208
FALL_DISTANCE, FACEPLANT_TIME = 30, 1.4                  # SS_Config:225-226
REMOUNT_RANGE, REMOUNT_GRACE = 9, 0.4                    # SS_Config:227-228
CAM_BACK, CAM_LAG, FADE_SPEED = 24, 7, 10                # SS_Config:250, 255
BOT_CAP = POOL["PerLane"] * LANE_COUNT + 10              # SS_Bot:433

# Species per zone: (name, SizeY, SizeZ, Speed, Fly, Rare, Big, Weight, Score)            SS_Config:56-142
def S(n, y, z, spd, fly=0, rare=False, big=False, w=1.0, score=1):
    return dict(name=n, y=y, z=z, spd=spd, fly=fly, rare=rare, big=big, w=w, score=score)

SPECIES = [
    [S("Taiga Elk", 5, 10, 1), S("Woolly Reindeer", 4.5, 9, 1.15), S("Musk Ox Calfrunner", 5, 9, 0.75),
     S("Snowshoe Hare-Hound", 4, 8, 1.5), S("Pine Boar", 3.5, 8, 0.85),
     S("Snowcrest Bull Elk", 7, 14, 1.3, rare=True, big=True, w=0.25, score=3),
     S("Pine Owlhawk", 2, 5, 1.25, fly=14, w=0.5)],
    [S("Rime Stag", 5, 9.5, 1), S("Mistwool Llama", 4.5, 9, 0.9), S("Hoarfrost Wolf", 5, 9.5, 1.15),
     S("Birchback Bison", 5.5, 10.5, 0.75), S("Fogtail Fox", 3.5, 8, 1.3)],
    [S("Crevasse Ibex", 4.5, 8.5, 1), S("Glacier Chamois", 4.5, 8, 1.45), S("Frostback Takin", 5, 9, 0.75),
     S("Rime Moose", 5.5, 10, 1), S("Glacier Saiga", 4.5, 9, 1.2),
     S("Glacier Mammoth", 8, 15, 1.25, rare=True, big=True, w=0.25, score=3),
     S("Crevasse Gull-Kite", 2, 5, 1.3, fly=15, w=0.5)],
    [S("Lumen Elk", 5, 9.5, 1.05), S("Cave Frost Bear", 5.5, 10, 0.8), S("Shardback Armadillo", 4.5, 9.5, 0.75),
     S("Glowtail Lynx", 4, 8, 1.4), S("Drip-Ice Tapir", 5, 9.5, 0.95)],
    [S("Steam Buffalo", 5.5, 10, 0.8), S("Onsen Capybara", 4.5, 9, 0.85), S("Geyser Goat", 4.5, 8.5, 1.2),
     S("Travertine Antelope", 4.5, 8.5, 1.4), S("Sulfur Boar", 4, 9, 0.85)],
    [S("Ember Yak", 5, 9.5, 1), S("Basalt Rhino-Goat", 4.5, 9, 0.8), S("Steam Bison", 5.5, 10, 0.75),
     S("Obsidian Gazelle", 4, 8, 1.5), S("Ashmane Wild Horse", 5, 10, 1.2),
     S("Magma Behemoth", 8, 15, 1.2, rare=True, big=True, w=0.25, score=3),
     S("Ash Roc", 2.5, 6, 1.35, fly=16, w=0.5),
     S("Cinder Wyvern", 3.5, 12, 1.6, fly=18, rare=True, w=0.05, score=5),
     S("Lava Drake", 3.5, 12, 1.6, fly=18, rare=True, w=0.05, score=5)],
    [S("Thunder Yak", 5.5, 10, 0.8), S("Stormmane Stallion", 4.5, 10, 1.15), S("Stormcrest Gazelle", 4, 8.5, 1.4),
     S("Rumble Rhino", 5, 10, 0.75), S("Static Wolf", 4.5, 9, 1.1)],
    [S("Windrunner Pronghorn", 4.5, 9, 1.4), S("Spire Markhor", 4.5, 9, 0.95), S("Frostdune Camel", 5.5, 10, 0.75),
     S("Gale Snow Leopard", 4, 8.5, 1.2), S("Spirehorn Oryx", 4.5, 9.5, 0.95)],
    [S("Nimbus Ostrich", 5, 8, 1.35), S("Cloudmane Horse", 4.5, 10, 1), S("Halo Deer", 4.5, 9, 1.05),
     S("Skyfleece Sheep", 5, 9, 0.75), S("Mistwing Kudu", 4.5, 9.5, 1.15)],
    [S("Crystal Ram", 4.5, 8.5, 1.05), S("Skyhorn Antelope", 4.5, 8.5, 1.45), S("Aurora Hart", 4.5, 9, 1),
     S("Gale Kirin-Horse", 4.5, 9.5, 1.1), S("Starfrost Ox", 5.5, 10, 0.75),
     S("Crown Colossus Ram", 8, 14, 1.25, rare=True, big=True, w=0.25, score=3),
     S("Frost Swiftwing", 2, 5, 1.4, fly=16, w=0.5),
     S("Aurora Dragon", 4, 14, 1.7, fly=20, rare=True, w=0.05, score=5),
     S("Starwing Drake", 3.5, 12, 1.7, fly=20, rare=True, w=0.05, score=5),
     S("Crystal Phoenix", 3, 10, 1.8, fly=22, rare=True, w=0.05, score=5)],
]

STARTS = []
_acc = 0
for _z in ZONES:
    STARTS.append(_acc)
    _acc += _z[1]
TOTAL = _acc  # 17,960 (SECTIONS-PLAN section 1)
NZ = len(ZONES)


def smooth(a):
    a = min(max(a, 0.0), 1.0)
    return a * a * (3 - 2 * a)


def zone_of(d):  # SS_Path:48, 0-based here
    k = 0
    for i in range(1, NZ):
        if d >= STARTS[i]:
            k = i
    return k


def zone_end(k):
    return STARTS[k] + ZONES[k][1]


def lane_width(d):  # SS_Path:63
    k = zone_of(d)
    w = ZONES[k][2]
    if k + 1 < NZ:
        a = (d - (zone_end(k) - NARROW_RAMP)) / NARROW_RAMP
        if a > 0:
            w += (ZONES[k + 1][2] - w) * min(a, 1)
    return w


def lane_x(lane, d):  # SS_Path:76
    return (lane - (LANE_COUNT + 1) / 2) * lane_width(d)


def speed_at(d):  # SS_Path:201
    d = max(d, 0.0)
    k = zone_of(d)
    v = ZONES[k][3]
    if k > 0:
        v = ZONES[k - 1][3] + (v - ZONES[k - 1][3]) * smooth((d - STARTS[k]) / SPEED_RAMP)
    return v


def pct(xs, p):
    if not xs:
        return float("nan")
    xs = sorted(xs)
    i = min(len(xs) - 1, max(0, int(math.ceil(p / 100 * len(xs))) - 1))
    return xs[i]


class Creature:
    __slots__ = ("k", "sp", "name", "y", "z", "fly", "rare", "big", "score", "spd", "spd0", "d", "lane", "xo",
                 "passT", "parked", "fade", "spawnT", "despawnT", "uid", "life", "fadeDur")

    def __init__(self, k, sp, rng, uid):
        s = SPECIES[k][sp]
        self.k, self.sp, self.name, self.uid = k, sp, s["name"], uid
        self.y, self.z, self.fly, self.rare, self.big, self.score = s["y"], s["z"], s["fly"], s["rare"], s["big"], s["score"]
        self.spd = self.spd0 = s["spd"] * (1 + (rng.random() * 2 - 1) * SPEED_JITTER)  # SS_Ride:97
        self.d, self.lane, self.xo, self.passT = float(STARTS[k]), 1, 0.0, 0.0
        self.parked, self.fade, self.spawnT, self.despawnT = True, 0.0, None, None
        self.life = 0
        self.fadeDur = 1.0

    def h(self):  # body centre height above the slope
        return self.y / 2 + self.fly

    def x(self):
        return lane_x(self.lane, self.d) + self.xo


# Rider policies: score(creature) -> desirability; swap when best reachable beats the mount by a margin.
TIERS = {"slow": 0.8, "normal": 1.0, "fast": 1.4}


def policy_score(policy, c):
    if policy in TIERS:
        if c.fly:
            return -9  # tier runs keep to the ground tiers
        return -abs(c.spd0 - TIERS[policy])
    if policy == "flyer":
        return (10 if c.fly else 0) + c.spd0
    if policy == "greedy":  # maximise score rate: points per stud x speed
        return c.score * c.spd0
    return 0.0


class Sim:
    def __init__(self, a):
        self.a = a
        self.rng = random.Random(a.seed)
        self.P = dict(POOL)
        self.P.update(Behind=a.behind, Ahead=a.ahead, PerLane=a.per_lane, ViewDist=a.view_dist,
                      FrontBand=a.front_band)
        self.rare_mul = [a.rare] * NZ
        if a.rare_zones:
            self.rare_mul = [a.rare if (k + 1) in a.rare_zones else 1.0 for k in range(NZ)]
        self.now = 0.0
        self.ts = 1.0
        self.build_pools()
        self.herd = []
        self.state = "none"
        self.mount = self.target = self.leap = None
        self.lastR = None
        self.st = dict(sec_time=[None] * (NZ + 1), ride_t=[0.0] * NZ, opps=[0] * NZ, notarget=[[] for _ in range(NZ)],
                       remount=[[] for _ in range(NZ)], stuck=[0] * NZ, live_max=[0] * NZ, live_samples=[[] for _ in range(NZ)],
                       biomes_max=[0] * NZ, seen_bot=[0] * NZ, seen_strict=[0] * NZ, fade_view=[0] * NZ,
                       min_gap=[math.inf] * NZ, ahead_min=[10 ** 9] * NZ, swaps=[0] * NZ, fails=[0] * NZ,
                       rare_seen=set(), rare_reach=set(), fly_seen=set(), fly_reach=set(), rare_rides=0, fly_rides=0,
                       native=[[] for _ in range(NZ)], native_border=[[] for _ in range(NZ)],
                       mount_spd_t=[0.0] * NZ, game_t=[0.0] * NZ, recycles=0)
        self.reach_prev = set()
        self.nt_start = None
        self.next_decide = 0.0

    # --- pools (SS_Ride:164-195) ------------------------------------------------------------------
    def build_pools(self):
        self.pools, self.w = [], []
        uid = 0
        for k in range(NZ):
            common, extra, total, extraW = [], [], 0.0, 0.0
            for i, s in enumerate(SPECIES[k]):
                sw = s["w"]
                if sw < 1:
                    sw *= self.rare_mul[k]
                    extra.append((i, sw))
                    extraW += sw
                else:
                    common.append(i)
                total += sw
            self.w.append(dict(common=common, extra=extra, total=total, extraW=extraW))
            pool = []
            for n in range(1, self.per_lane(k) * LANE_COUNT + 1):
                uid += 1
                pool.append(Creature(k, common[n % len(common)], self.rng, uid))
            for i, _ in extra:
                for _ in range(self.P["ExtraEach"]):
                    uid += 1
                    pool.append(Creature(k, i, self.rng, uid))
            self.pools.append(pool)

    def per_lane(self, k):
        return self.a.per_lane_sec[k] if self.a.per_lane_sec else self.P["PerLane"]

    def ahead_at(self, r):  # --ahead-secs (not in SS_Ride): window ahead = rider-section Speed x seconds
        if not self.a.ahead_secs:
            return self.P["Ahead"]
        return max(self.a.ahead_min, ZONES[zone_of(min(max(r, 0), TOTAL - 1))][3] * self.a.ahead_secs)

    def protected(self, c):
        return c is self.mount or c is self.target or (self.leap is not None and c is self.leap["from"])

    def vd(self, r):  # Pool.ViewDist (per section from the P4 fog table: the rider's section)
        v = self.a.view_dist_sec
        return v[zone_of(min(max(r, 0), TOTAL - 1))] if v else self.P["ViewDist"]

    def ra(self, r):  # RecycleAhead (per section, as ViewDist)
        v = self.a.recycle_ahead_sec
        return v[zone_of(min(max(r, 0), TOTAL - 1))] if v else self.a.recycle_ahead

    def in_seen(self, d, r):
        return r - self.a.recycle_clear < d < r + self.ra(r)

    def cam_d(self, r):  # steady-state chase camera: Back behind, plus the Lag of a moving anchor
        v = self.rider_v()
        return r - CAM_BACK - v / CAM_LAG

    def on_screen(self, d, r, dist):  # the camera looks up the slope; FOV covers all lanes past ~40 studs
        cd = self.cam_d(r)
        return cd < d < cd + dist

    def rider_v(self):
        m = self.mount or (self.leap and self.leap["from"])
        return speed_at(self.rider_d()) * m.spd if m else 0.0

    def rider_d(self):
        if self.leap:
            return self.leap["d"]
        if self.mount:
            return self.mount.d
        if self.target:
            return self.target.d
        return self.foot_d

    def park(self, c, r, quiet):
        k = zone_of(min(max(r, 0), TOTAL - 1))
        if not quiet and c.fade < 0.95:
            if self.on_screen(c.d, r, self.vd(r)):
                self.st["seen_bot"][k] += 1
            if self.on_screen(c.d, r, self.a.vis):
                self.st["seen_strict"][k] += 1
        c.parked, c.despawnT, c.xo, c.spd = True, None, 0.0, c.spd0
        self.dirty = True

    def unpark(self, c, quiet, r):
        k = zone_of(min(max(r, 0), TOTAL - 1))
        c.parked = False
        c.life += 1
        c.fade = 0.0 if quiet else 1.0
        # --far-fade (P4, owner: slow far fade-in): a respawn ahead of the rider fades in over FarFade s
        c.fadeDur = self.a.far_fade if (self.a.far_fade and c.d > r) else self.P["FadeIn"]
        c.spawnT = None if quiet else self.now
        if not quiet and c.fadeDur < (self.a.far_fade or 0) - 1e-9 and self.a.readable_sec:
            if self.on_screen(c.d, r, self.a.readable_sec[k]):
                self.st["fast_pops"] = self.st.get("fast_pops", 0) + 1  # a quick fade-in a player could read
        if not quiet:
            if self.on_screen(c.d, r, self.vd(r)):
                self.st["seen_bot"][k] += 1
            if self.on_screen(c.d, r, self.a.vis):
                self.st["seen_strict"][k] += 1
        self.herd.append(c)
        self.st["recycles"] += 1
        self.dirty = True

    def free_at(self, c, lane, d):
        cf = c.fly > 0
        for o in self.herd:
            if o is not c and not o.parked and o.lane == lane and (o.fly > 0) == cf and abs(o.d - d) < (o.z + c.z) / 2 + LANE_GAP:
                return False
        return True

    def place(self, c, lo, hi, pref):
        if hi - lo < 1:
            return False
        for t in range(1, self.P["Tries"] + 1):
            d = lo + self.rng.random() * (hi - lo)
            lane = pref if (t == 1 and pref) else self.rng.randint(1, LANE_COUNT)
            if self.free_at(c, lane, d):
                c.d, c.lane, c.xo, c.passT = d, lane, 0.0, 0.0
                return True
        return False

    def bands_for(self, c, k, r, rk, riderV):  # SS_Ride:960
        P = self.P
        s, e = STARTS[k], min(zone_end(k), TOTAL) - 1
        hi = min(e, r + P["Ahead"])
        near = max(self.ra(r), self.vd(r))
        fb = P["FrontBand"] if P["FrontBand"] is not None else P["Ahead"] - near  # None: the whole r+near..Ahead
        far = (max(s, r + near, r + P["Ahead"] - fb), hi)
        front = (max(s, r + near), hi)
        if k != rk:
            return [far, front]
        rear = (max(s - P["Behind"], r - P["Behind"]), min(e, r - self.a.recycle_clear))
        if speed_at(max(rear[1], 0)) * c.spd > riderV:
            return [rear, far]
        return [far, front]

    def quota(self, k, lo, hi, rk):  # SS_Ride:977
        if k < rk:
            return 0
        s = STARTS[k] - self.P["Behind"] if k == rk else STARTS[k]
        ov = min(zone_end(k), hi) - max(s, lo)
        if ov <= 0:
            return 0
        return math.ceil(self.per_lane(k) * LANE_COUNT * ov / (self.P["Behind"] + self.P["Ahead"]))

    def candidates(self, k):  # SS_Ride:990
        w = self.w[k]
        live, parked_by = {}, {}
        for c in self.pools[k]:
            if c.parked:
                parked_by.setdefault(c.sp, c)
            else:
                live[c.sp] = live.get(c.sp, 0) + 1
        out = []
        if w["extraW"] > 0 and self.rng.random() < w["extraW"] / w["total"]:
            roll = self.rng.random() * w["extraW"]
            for i, ew in w["extra"]:
                roll -= ew
                if roll <= 0:
                    if i in parked_by:
                        out.append(parked_by[i])
                    break
        commons = [i for i in w["common"] if i in parked_by]
        commons.sort(key=lambda i: live.get(i, 0))  # Lua table.sort is unstable; Python's is stable
        out += [parked_by[i] for i in commons]
        return out

    def pool_step(self, r, jump):  # SS_Ride:1025
        P = self.P
        P["Ahead"] = self.ahead_at(r)
        lo, hi = r - P["Behind"], r + P["Ahead"]
        rk = zone_of(min(max(r, 0), TOTAL - 1))
        rspd = (self.leap and self.leap["spd"]) or (self.mount and self.mount.spd) or 0
        for k in range(NZ):
            s, e = STARTS[k], zone_end(k)
            q = self.quota(k, lo, hi, rk)
            pool = self.pools[k]
            # --quota-natives (P4 fix): a straggler past its biome's end no longer fills that biome's quota
            # (only while the rider is on foot in this biome: else the stragglers would pile up on top of the quota)
            skip = self.a.quota_natives and rspd == 0 and k == rk
            counted = lambda c: not (skip and c.d >= e and not self.protected(c))
            # SS_Ride (P4 re-review): live = staying, leaving = fading out ahead; a leaver no longer counts as staying
            live = sum(1 for c in pool if not c.parked and counted(c) and c.despawnT is None)
            leaving = sum(1 for c in pool if not c.parked and counted(c) and c.despawnT is not None)
            if live + leaving == 0 and q == 0:
                continue
            for c in pool:
                if not c.parked and not self.protected(c):
                    done = c.d >= TOTAL and c.fade >= 0.95
                    outside = c.d < lo or c.d > hi or c.d < s - P["Behind"] or c.d >= e
                    over = (live >= q) if c.despawnT is not None else (live > q)
                    if jump or done or (not self.in_seen(c.d, r) and (outside or over)):
                        if not jump and not done and c.d > r and c.fade < 0.95:
                            if c.despawnT is None:
                                c.despawnT = self.now
                                if counted(c):
                                    live, leaving = live - 1, leaving + 1
                                if self.on_screen(c.d, r, self.a.vis):
                                    self.st["fade_view"][rk] += 1
                        else:
                            was = c.despawnT is not None
                            self.park(c, r, jump or done)
                            if counted(c):
                                if was:
                                    leaving -= 1
                                else:
                                    live -= 1
                    elif c.despawnT is not None:  # called off: back in as slowly as it left (FarFade)
                        c.despawnT = None
                        fd = self.a.far_fade or self.P["FadeIn"]
                        c.fadeDur = fd
                        c.spawnT = self.now - (1 - c.fade) * fd
                        if counted(c):
                            live, leaving = live + 1, leaving - 1
            budget = 10 ** 9 if jump else P["SpawnPerFrame"]
            riderV = speed_at(max(r, 0)) * rspd
            pref = self.foot_lane if (rspd == 0 and k == rk) else None
            while live + leaving < q and budget > 0:
                budget -= 1
                got = None
                for c in self.candidates(k):
                    if jump or k == rk or speed_at(s) * c.spd < riderV:
                        ok = False
                        if jump:
                            ok = self.place(c, max(s, lo), min(min(e, TOTAL) - 1, hi), None)
                        else:
                            for b in self.bands_for(c, k, r, rk, riderV):
                                if self.place(c, b[0], b[1], pref):
                                    ok = True
                                    break
                        if ok:
                            got = c
                            break
                if not got:
                    break
                self.unpark(got, jump, r)
                live += 1
        if self.dirty:
            self.dirty = False
            self.herd = [c for k in range(NZ) for c in self.pools[k] if not c.parked]

    # --- herd motion + lane solver (SS_Ride:1146-1227) --------------------------------------------
    def herd_step(self, dt):
        g = dt * self.ts
        drop = self.a.straggler_drop
        for c in self.herd:
            if c is self.mount or c is self.target:
                c.spd = c.spd0  # a ridden creature never tires
            elif drop < 1 and c.d >= zone_end(c.k):
                # --straggler-drop (not in SS_Ride): past its own biome a creature tires and falls back
                c.spd = max(c.spd0 * drop, c.spd - c.spd0 * 0.5 * g)  # TireRate in game time (SS_Ride: dt x timeScale)
            c.d += speed_at(c.d) * c.spd * g
            if c.xo != 0:
                c.xo *= math.exp(-PASS_EASE * g)
                if abs(c.xo) < 0.01:
                    c.xo = 0.0
        lanes = {}
        for c in self.herd:
            lanes.setdefault(-c.lane if c.fly > 0 else c.lane, []).append(c)
        fixed = lambda c: c is self.mount or c is self.target

        def need(lead, c):
            return c.d + (lead.z + c.z) / 2 + LANE_GAP

        for key, l in lanes.items():
            lane = abs(key)
            l.sort(key=lambda c: -c.d)

            def push():  # the ridden creature pushes the chain ahead, over the creatures still in this lane
                for i in range(len(l) - 1, 0, -1):
                    if fixed(l[i]):
                        behind = l[i]
                        for j in range(i - 1, -1, -1):
                            lj = l[j]
                            if lj.lane != lane:
                                continue
                            if fixed(lj) or lj.d >= need(lj, behind):
                                break
                            # --yield (in SS_Ride since P2b): a creature the ridden one pushes steps aside if it can
                            if self.a.yield_ and self.now >= lj.passT and self.overtake(lj):
                                break
                            lj.d = need(lj, behind)
                            behind = lj
            if self.a.push_first:  # the pre-P4 order (comparison only)
                push()
            lead = None  # the nearest one still in this lane (SS_Ride: one that pulled out no longer drags c back)
            for c in l:
                if lead is not None and not fixed(c) and lead.d < need(lead, c):
                    # --yield: behind the ridden creature any tier difference is enough to pull out
                    faster = c.spd > lead.spd * (1.0 if (self.a.yield_ and fixed(lead)) else 1.05)
                    if faster and self.now >= c.passT and self.overtake(c):
                        continue
                    c.d = lead.d - (lead.z + c.z) / 2 - LANE_GAP
                if c.lane == lane:
                    lead = c
            if not self.a.push_first:  # SS_Ride (P4 re-review): the push runs after the followers
                push()

    def overtake(self, c):
        c.passT = self.now + PASS_RETRY
        order = (-1, 1) if self.rng.random() < 0.5 else (1, -1)
        for dl in order:
            nl = c.lane + dl
            if 1 <= nl <= LANE_COUNT:
                free = True
                for o in self.herd:
                    if o is not c and o.lane == nl and (o.fly > 0) == (c.fly > 0) and abs(o.d - c.d) < (o.z + c.z) / 2 + LANE_GAP:
                        free = False
                        break
                if free:
                    c.xo += lane_x(c.lane, c.d) - lane_x(nl, c.d)
                    c.lane = nl
                    return True
        return False

    # --- rider ----------------------------------------------------------------------------------------
    def reachable(self):
        m = self.mount
        mx, mh = m.x(), m.h()
        out = []
        for c in self.herd:
            if c is not m:
                dd = c.d - m.d
                if abs(dd) <= SWAP_RANGE:
                    if dd * dd + (c.x() - mx) ** 2 + (c.h() - mh) ** 2 <= SWAP_RANGE * SWAP_RANGE:
                        out.append(c)
        return out

    def start_jump(self, c):
        self.target = c
        self.state, self.stateT = "jump", 0.0

    def fail(self):
        k = zone_of(min(max(self.mount.d, 0), TOTAL - 1))
        self.st["fails"][k] += 1
        self.fall_from = self.mount.d
        self.foot_to = max(self.mount.d - FALL_DISTANCE, 0)
        self.foot_lane = self.mount.lane
        self.foot_d = self.mount.d
        self.fall_clock = self.now
        self.fall_k = k
        self.mount = self.target = None
        self.state, self.stateT = "fall", 0.0

    def leap_step(self, dt):
        L, lp = LEAP, self.leap
        lp["real"] += dt
        kin = min(max(lp["real"] / L["EaseIn"], 0), 1)
        kout = min(max((lp["T"] - lp["t"]) / L["EaseOut"], 0), 1)
        if lp["real"] > L["MaxSlow"]:
            kout = min(kout, min(max(1 - (lp["real"] - L["MaxSlow"]) / 0.3, 0), 1))
        kk = smooth(min(kin, kout))
        self.ts = 1 - (1 - L["Slow"]) * kk
        g = dt * self.ts
        lp["t"] += g
        # the flight closes on the target's back (auto-target + Magnet): linear in game time here
        tgt = self.target
        f = min(lp["t"] / lp["T"], 1)
        lp["d"] = lp["d0"] + (tgt.d - 0.5 - lp["d0"]) * f
        if lp["t"] >= lp["T"]:
            self.ts = 1.0
            self.leap = None
            self.mount, self.target = tgt, None
            self.state = "ride"
            self.on_mount(tgt)

    def on_mount(self, c):
        if c.rare:
            self.st["rare_rides"] += 1
        if c.fly:
            self.st["fly_rides"] += 1

    def rider_step(self, dt):
        a, st = self.a, self.st
        self.stateT += dt
        if self.state == "ride":
            m = self.mount
            k = zone_of(min(max(m.d, 0), TOTAL - 1))
            st["ride_t"][k] += dt
            st["mount_spd_t"][k] += m.spd * dt
            st["score"] = st.get("score", 0.0) + speed_at(m.d) * m.spd * dt * self.ts * m.score  # SS_Ride: ScoreRate 1
            reach = self.reachable()
            ids = {c.uid for c in reach}
            st["opps"][k] += len(ids - self.reach_prev)
            self.reach_prev = ids
            if not reach:
                if self.nt_start is None:
                    self.nt_start = (self.now, k)
            elif self.nt_start is not None:
                st["notarget"][self.nt_start[1]].append(self.now - self.nt_start[0])
                self.nt_start = None
            if m.d >= TOTAL:
                return "summit"
            if self.now >= self.next_decide and reach and a.policy != "none":
                self.next_decide = self.now + a.cadence
                pick = None
                if a.policy == "casual":
                    if self.rng.random() < a.casual_rate:
                        pick = self.rng.choice(reach)
                else:
                    best = max(reach, key=lambda c: policy_score(a.policy, c))
                    if policy_score(a.policy, best) > policy_score(a.policy, m) + 0.05:
                        pick = best
                if pick:
                    self.close_nt()
                    st["swaps"][k] += 1
                    self.target = pick
                    self.state, self.stateT = "stance", 0.0
                    self.will_fail = self.rng.random() < a.p_fail
                    self.press_at = STANCE_TIME + (self.rng.uniform(0.15, 0.4) if self.will_fail else IDEAL_PRESS)
                    self.power = self.rng.uniform(0.5, 1.0)
        elif self.state == "stance":
            if self.stateT >= self.press_at:
                if self.will_fail:
                    self.fail()
                else:
                    m = self.mount
                    self.leap = dict(d=m.d, d0=m.d, t=0.0, real=0.0, T=LEAP["Time"] + LEAP["PowerTime"] * self.power,
                                     spd=m.spd, **{"from": m})
                    self.mount = None
                    self.state = "leap"
        elif self.state == "leap":
            self.leap_step(dt)
        elif self.state == "fall":
            e = 1 - (1 - min(self.stateT / FACEPLANT_TIME, 1)) ** 2
            self.foot_d = self.fall_from + (self.foot_to - self.fall_from) * e
            if self.stateT >= FACEPLANT_TIME:
                self.state, self.stateT = "free", 0.0
                self.free_since = self.now
        elif self.state == "free":
            waited = self.now - self.fall_clock
            if waited > a.stuck_after:
                st["stuck"][self.fall_k] += 1
                st["remount"][self.fall_k].append(waited)
                return "stuck"
            if self.now - self.free_since >= REMOUNT_GRACE:
                px = lane_x(self.foot_lane, self.foot_d)
                for c in self.herd:
                    if c.fly == 0 and abs(c.d - self.foot_d) < REMOUNT_RANGE and abs(lane_x(c.lane, c.d) - px) < lane_width(c.d) * 0.6:
                        st["remount"][self.fall_k].append(waited)
                        self.start_jump(c)
                        break
        elif self.state == "jump":
            if self.stateT >= JUMP_TIME:
                self.mount, self.target = self.target, None
                self.state = "ride"
                self.on_mount(self.mount)
        return None

    def close_nt(self):
        if self.nt_start is not None:
            self.st["notarget"][self.nt_start[1]].append(self.now - self.nt_start[0])
            self.nt_start = None

    def fades(self, dt, r):
        a = 1 - math.exp(-FADE_SPEED * dt)
        for c in self.herd:
            want = 0.0
            if c is not self.mount and c is not self.target and c.d > TOTAL - SUMMIT_FADE:
                want = min((c.d - TOTAL + SUMMIT_FADE) / SUMMIT_FADE, 1)
            if c.spawnT is not None:
                f = 1 - (self.now - c.spawnT) / c.fadeDur
                if f > 0:
                    want = max(want, f)
                else:
                    c.spawnT = None
            if c.despawnT is not None:
                out = self.a.far_fade if (self.a.far_fade and c.d > r) else self.P["FadeIn"]  # leaving ahead: as slow
                want = max(want, min((self.now - c.despawnT) / out, 1))
            c.fade = 1.0 if want == 1 else c.fade + (want - c.fade) * a
            if c.fade < 0.01:
                c.fade = 0.0

    def measure(self, r):
        st = self.st
        k = zone_of(min(max(r, 0), TOTAL - 1))
        free = [c for c in self.herd if not self.protected(c)]
        n = len(free)
        st["live_max"][k] = max(st["live_max"][k], n)
        st["live_samples"][k].append(n)
        st["biomes_max"][k] = max(st["biomes_max"][k], len({c.k for c in free}))
        if r < TOTAL - 300:  # the BOT's "300 studs ahead never run empty" (SS_Bot:450), not past the summit
            ahead = sum(1 for c in self.herd if c is not self.mount and r < c.d < r + 300)
            st["ahead_min"][k] = min(st["ahead_min"][k], ahead)
        near = [c for c in self.herd if c is not self.mount and self.in_seen(c.d, r)]
        if near:  # share of creatures near the rider that are the rider's biome (SS_Bot:449 "native")
            nat = sum(1 for c in near if c.k == k) / len(near)
            st["native"][k].append(nat)
            if 250 <= r - STARTS[k] < 300:
                st["native_border"][k].append(nat)
        lanes = {}
        for c in self.herd:
            lanes.setdefault(-c.lane if c.fly > 0 else c.lane, []).append(c)
        for l in lanes.values():
            l.sort(key=lambda c: -c.d)
            for i in range(1, len(l)):
                g = l[i - 1].d - l[i].d - (l[i - 1].z + l[i].z) / 2
                if g < st["min_gap"][k]:
                    st["min_gap"][k] = g
        vis = self.a.vis
        for c in self.herd:
            if c.fade < 0.5 and self.on_screen(c.d, r, vis):
                if c.rare:  # one encounter per respawn of a creature
                    st["rare_seen"].add((c.uid, c.life))
                if c.fly:
                    st["fly_seen"].add((c.uid, c.life))
        if self.mount:
            for c in self.reachable():
                if c.rare:
                    st["rare_reach"].add((c.uid, c.life))
                if c.fly:
                    st["fly_reach"].add((c.uid, c.life))

    def run_10d(self):
        """BOT 10d (SS_Bot ride10d): teleport the mount to section 2 +300 (the pool re-lays the window), pin it
        at tier 1, never swap, ride to section 4 +300. Samples every frame after the BOT's 2 s wait, per run:
        empty ahead (nothing but the mount in r..r+300) share + longest, in-view respawns/parks (camera within the
        rider section's ViewDist), no target (nothing in SwapRange) share + longest, mean ahead."""
        a = self.a
        dt = 1.0 / a.fps
        frm, to = STARTS[1] + 300, STARTS[3] + 300
        self.dirty = False
        self.foot_d, self.foot_lane = -30.0, 3
        self.pool_step(-30.0, True)  # the BOT starts from a normal spawn, then teleports its mount
        m = min((c for c in self.herd if c.fly == 0), key=lambda c: (c.lane != 3, c.d))
        self.mount, self.state, self.stateT = m, "ride", 0.0
        m.d = frm
        self.pool_step(frm, True)
        self.lastR = frm
        m.spd = m.spd0 = 1.0  # mountSpd 1
        a.policy = "none"
        T = dict(t=0.0, empty=0.0, run=0.0, longest=0.0, nt=0.0, ntrun=0.0, ntlong=0.0, ahead_sum=0.0, n=0, seen0=None,
                 live=0, str_sum=0.0, str_max=0.0)
        while self.now < 300:
            self.now += dt
            self.herd_step(dt)
            r = self.rider_d()
            jump = abs(r - self.lastR) > 40
            self.lastR = r
            self.pool_step(r, jump)
            self.rider_step(dt)
            r = self.rider_d()
            self.fades(dt, r)
            if r >= to or self.mount is None:
                break
            if self.now < 2.0:
                continue
            if T["seen0"] is None:
                T["seen0"] = sum(self.st["seen_bot"])
            ahead = sum(1 for c in self.herd if c is not self.mount and r < c.d < r + 300)
            free = [c for c in self.herd if not self.protected(c)]  # SS_Ride herdStats: live, stragglers
            strag = sum(1 for c in free if c.d >= zone_end(c.k) or c.d < STARTS[c.k] - self.P["Behind"])
            T["live"] = max(T["live"], len(free))
            sh = strag / len(free) if free else 0.0
            T["str_sum"] += sh
            T["str_max"] = max(T["str_max"], sh)
            T["t"] += dt
            T["n"] += 1
            T["ahead_sum"] += ahead
            T["run"] = T["run"] + dt if ahead == 0 else 0.0
            T["empty"] += dt if ahead == 0 else 0.0
            T["longest"] = max(T["longest"], T["run"])
            reach = self.reachable()
            T["ntrun"] = T["ntrun"] + dt if not reach else 0.0
            T["nt"] += dt if not reach else 0.0
            T["ntlong"] = max(T["ntlong"], T["ntrun"])
        t = max(T["t"], 1e-9)
        return dict(time=T["t"], reached=self.rider_d() >= to, empty=T["empty"] / t, empty_long=T["longest"],
                    fast_pops=self.st.get("fast_pops", 0),
                    seen=sum(self.st["seen_bot"]) - (T["seen0"] or 0), nt=T["nt"] / t, nt_long=T["ntlong"],
                    ahead_mean=T["ahead_sum"] / max(T["n"], 1), live=T["live"],
                    cap=max(self.per_lane(k) for k in (1, 2, 3)) * LANE_COUNT + 25,  # SS_Bot 10d (+25 since P4)
                    str_avg=T["str_sum"] / max(T["n"], 1), str_max=T["str_max"])

    def run(self):
        a = self.a
        dt = 1.0 / a.fps
        self.dirty = False
        self.foot_d, self.foot_lane = -30.0, 3
        # summit reset: re-lay the window at -30 and jump onto the lowest middle-lane zone-1 ground creature
        self.pool_step(-30.0, True)
        self.lastR = -30.0
        mid = (LANE_COUNT + 1) // 2
        best = None
        for h in self.herd:
            if h.k == 0 and h.fly == 0 and h.d >= 0 and (best is None or (h.lane == mid and best.lane != mid)
                                                         or ((h.lane == mid) == (best.lane == mid) and h.d < best.d)):
                best = h
        self.start_jump(best)
        self.stateT = 0.0
        self.st["sec_time"][0] = 0.0
        last_k = 0
        frame = 0
        end = "summit"
        while True:
            frame += 1
            self.now += dt
            self.herd_step(dt)
            r = self.rider_d()
            jump = self.lastR is not None and abs(r - self.lastR) > 40
            self.lastR = r
            self.pool_step(r, jump)
            res = self.rider_step(dt)
            r = self.rider_d()
            self.fades(dt, r)
            k = zone_of(min(max(r, 0), TOTAL - 1))
            self.st["game_t"][k] += dt * self.ts
            if frame % a.measure_every == 0:
                self.measure(r)
            while last_k + 1 < NZ and r >= STARTS[last_k + 1]:
                last_k += 1
                self.st["sec_time"][last_k] = self.now
            if res:
                end = res
                break
            if self.now > a.max_time:
                end = "timeout"
                break
        self.close_nt()
        self.st["sec_time"][NZ] = self.now if end == "summit" else None
        self.st["end"] = end
        self.st["total_time"] = self.now
        return self.st


# ---------------------------------------------------------------------------------------------------
def args_for(**kw):
    a = argparse.Namespace(policy="normal", per_lane=5, ahead=700, behind=150, view_dist=300, front_band=250,
                           vis=450, rare=1.0, rare_zones=None, seed=1, fps=30, cadence=0.75, casual_rate=0.5,
                           p_fail=0.15, per_lane_sec=None, view_dist_sec=None, recycle_ahead_sec=None, quota_natives=False, far_fade=0.0, readable_sec=None, push_first=False, ahead_secs=0.0, ahead_min=450.0, yield_=False, straggler_drop=1.0, recycle_clear=float(RECYCLE_CLEAR), recycle_ahead=float(RECYCLE_AHEAD), stuck_after=60.0, max_time=1500.0, measure_every=3)
    for k, v in kw.items():
        setattr(a, k, v)
    return a


def sec_times(st):
    t = st["sec_time"]
    return [(t[k + 1] - t[k]) if (t[k] is not None and t[k + 1] is not None) else None for k in range(NZ)]


def aggregate(runs):
    """Per-section aggregate over several runs (same config, different seeds)."""
    rows = []
    for k in range(NZ):
        ride = sum(r["ride_t"][k] for r in runs)
        opps = sum(r["opps"][k] for r in runs)
        nt = [x for r in runs for x in r["notarget"][k]]
        rm = [x for r in runs for x in r["remount"][k]]
        times = [sec_times(r)[k] for r in runs if sec_times(r)[k] is not None]
        live = [x for r in runs for x in r["live_samples"][k]]
        rows.append(dict(
            k=k + 1, opm=60 * opps / ride if ride else float("nan"),
            nt_mean=statistics.mean(nt) if nt else 0.0, nt_p95=pct(nt, 95) if nt else 0.0,
            nt_frac=(sum(nt) / ride) if ride else float("nan"),
            rm_n=len(rm), rm_mean=statistics.mean(rm) if rm else float("nan"), rm_p95=pct(rm, 95),
            rm_max=max(rm) if rm else float("nan"), stuck=sum(r["stuck"][k] for r in runs),
            time=statistics.mean(times) if times else float("nan"),
            spd=(sum(r["mount_spd_t"][k] for r in runs) / ride) if ride else float("nan"),
            live_max=max(r["live_max"][k] for r in runs), live_p95=pct(live, 95),
            biomes=max(r["biomes_max"][k] for r in runs),
            seen=sum(r["seen_bot"][k] for r in runs), seen_strict=sum(r["seen_strict"][k] for r in runs),
            fade_view=sum(r["fade_view"][k] for r in runs) / len(runs),
            gap=min(r["min_gap"][k] for r in runs), ahead_min=min(r["ahead_min"][k] for r in runs),
            swaps=sum(r["swaps"][k] for r in runs) / len(runs),
            native=statistics.mean([x for r in runs for x in r["native"][k]] or [float("nan")]),
            native_b=statistics.mean([x for r in runs for x in r["native_border"][k]] or [float("nan")]),
            # the BOT's 10d reads the minimum over +250..300 in one run: the worst run's minimum
            native_bmin=min((min(r["native_border"][k]) for r in runs if r["native_border"][k]), default=float("nan")),
        ))
    return rows


def runs_for(n, **kw):
    out = []
    for s in range(1, n + 1):
        out.append(Sim(args_for(seed=s, **kw)).run())
    return out


def f(x, nd=1):
    if x is None or (isinstance(x, float) and (math.isnan(x) or math.isinf(x))):
        return "-"
    return f"{x:.{nd}f}"


def section_table(rows, title):
    o = [f"#### {title}", "",
         "| Sec | Speed | swap opps/min | no-target mean / p95 s (share of ride) | remount n, mean / p95 / max s | "
         "section time s | mount spd avg | live max / p95 (cap %d) | biomes | native avg / @+250 | in view BOT / strict | fades in view /run | min gap | ahead>=  |" % BOT_CAP,
         "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in rows:
        k = r["k"] - 1
        o.append(f"| {r['k']} | {ZONES[k][3]:.1f} | {f(r['opm'])} | {f(r['nt_mean'])} / {f(r['nt_p95'])} ({f(100 * r['nt_frac'], 0)}%) | "
                 f"{r['rm_n']}, {f(r['rm_mean'])} / {f(r['rm_p95'])} / {f(r['rm_max'])}{' STUCK ' + str(r['stuck']) if r['stuck'] else ''} | "
                 f"{f(r['time'])} | {f(r['spd'], 2)} | {r['live_max']} / {f(r['live_p95'], 0)} | {r['biomes']} | {f(100 * r['native'], 0)}% / {f(100 * r['native_b'], 0)}% | {r['seen']} / {r['seen_strict']} | "
                 f"{f(r['fade_view'])} | {f(r['gap'])} | {r['ahead_min']} |")
    return "\n".join(o)


def run_summary(runs):
    rows = aggregate(runs)
    nt = [x for r in runs for k in range(NZ) for x in r["notarget"][k]]
    rm = [x for r in runs for k in range(NZ) for x in r["remount"][k]]
    ride = sum(sum(r["ride_t"]) for r in runs)
    tot = [r["total_time"] for r in runs if r["end"] == "summit"]
    return dict(
        opm=60 * sum(sum(r["opps"]) for r in runs) / ride,
        opm_min=min(x["opm"] for x in rows),
        nt_p95=pct(nt, 95), nt_frac=sum(nt) / ride, nt_worst=max(x["nt_frac"] for x in rows),
        rm_mean=statistics.mean(rm) if rm else float("nan"), rm_p95=pct(rm, 95), rm_max=max(rm) if rm else float("nan"),
        stuck=sum(sum(r["stuck"]) for r in runs), total=statistics.mean(tot) if tot else float("nan"),
        ends=",".join(sorted({r["end"] for r in runs})),
        live_max=max(x["live_max"] for x in rows), biomes=max(x["biomes"] for x in rows),
        native=statistics.mean(x["native"] for x in rows[1:]), native_b=statistics.mean(x["native_b"] for x in rows[1:]),
        native_bmin=min((x["native_bmin"] for x in rows[1:] if x["native_bmin"] == x["native_bmin"]), default=float("nan")),
        seen=sum(x["seen"] for x in rows), seen_strict=sum(x["seen_strict"] for x in rows),
        fade_view=sum(x["fade_view"] for x in rows), gap=min(x["gap"] for x in rows),
        ahead_min=min(x["ahead_min"] for x in rows),
        rare_seen=statistics.mean(len(r["rare_seen"]) for r in runs), rare_reach=statistics.mean(len(r["rare_reach"]) for r in runs),
        fly_seen=statistics.mean(len(r["fly_seen"]) for r in runs), fly_reach=statistics.mean(len(r["fly_reach"]) for r in runs),
        rare_rides=statistics.mean(r["rare_rides"] for r in runs), fly_rides=statistics.mean(r["fly_rides"] for r in runs),
        recycles=statistics.mean(r["recycles"] for r in runs), rows=rows,
    )


FIX = dict(yield_=True, straggler_drop=0.7, recycle_clear=60.0)
FIX_VARIANTS = [
    ("today (src)", {}),
    ("yield", dict(yield_=True)),
    ("yield+drop", dict(yield_=True, straggler_drop=0.7)),
    ("yield+drop+clear", FIX),
    ("yield+drop+clear+fb", dict(FIX, front_band=400)),
]


DENSITY_VARIANTS = [
    ("uniform PerLane 5, Ahead 700", {}),
    ("PerLane 8,7,6,6,5,5,5,5,4,4", dict(per_lane_sec=[8, 7, 6, 6, 5, 5, 5, 5, 4, 4])),
    ("Ahead = Speed x 9 s (min 450)", dict(ahead_secs=9.0, front_band=None)),
    ("both", dict(per_lane_sec=[8, 7, 6, 6, 5, 5, 5, 5, 4, 4], ahead_secs=9.0, front_band=None)),
]


def report(out, seeds):
    L = []
    w = L.append
    w("# herdsim results (MODEL output, not a playtest)\n")
    w(f"Generated by `python sim/herdsim.py report --seeds {seeds}`. Seeds 1..{seeds} per config; 30 fps; "
      "p_fail 0.15 per swap unless noted; decision cadence 0.75 s.\n")
    # 1. Baseline per section, per policy
    base = {}
    for pol in ["slow", "normal", "fast", "flyer", "greedy", "casual"]:
        runs = runs_for(seeds, policy=pol)
        base[pol] = run_summary(runs)
        if pol in ("normal", "greedy"):
            w(section_table(base[pol]["rows"], f"Baseline P2 (PerLane 5 = 25 live, Ahead 700), policy `{pol}`"))
            w("")
    w("#### Section time (s) by policy, baseline pool. Target 40 s at a tier-1 mount; `spd` = time-averaged mount tier\n")
    w("| Sec | ideal L/Speed | " + " | ".join(f"{p} s (spd)" for p in base) + " |")
    w("|---|---|" + "---|" * len(base))
    for k in range(NZ):
        ideal = ZONES[k][1] / ZONES[k][3]
        w(f"| {k + 1} | {ideal:.1f} | " + " | ".join(f"{f(base[p]['rows'][k]['time'])} ({f(base[p]['rows'][k]['spd'], 2)})" for p in base) + " |")
    w("| total | 400 | " + " | ".join(f(base[p]["total"]) for p in base) + " |")
    w("")
    w("#### Run totals by policy (baseline)\n")
    w("| policy | opps/min | no-target share | no-target p95 s | remount mean / p95 / max s | stuck | rare seen / reachable / ridden per run | flyer seen / reachable / ridden per run |")
    w("|---|---|---|---|---|---|---|---|")
    for p, s in base.items():
        w(f"| {p} | {f(s['opm'])} | {f(100 * s['nt_frac'], 0)}% | {f(s['nt_p95'])} | {f(s['rm_mean'])} / {f(s['rm_p95'])} / {f(s['rm_max'])} | {s['stuck']} | "
          f"{f(s['rare_seen'])} / {f(s['rare_reach'])} / {f(s['rare_rides'])} | {f(s['fly_seen'])} / {f(s['fly_reach'])} / {f(s['fly_rides'])} |")
    w("")
    # 2. Pool x window sweep
    w("#### Sweep: pool size (live quota = PerLane x 5) x window ahead, policy `normal`\n")
    w("| pool | ahead | opps/min (worst sec) | no-target share (worst sec) | no-target p95 s | remount mean / p95 / max s | stuck | live max (cap) | biomes | in view BOT / strict | fades in view /run | min gap | ahead>= | recycles/run |")
    w("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    sweep = {}
    for pl in (3, 5, 7):
        for ah in (500, 700, 900):
            s = run_summary(runs_for(seeds, policy="normal", per_lane=pl, ahead=ah))
            sweep[(pl, ah)] = s
            w(f"| {pl * 5} | {ah} | {f(s['opm'])} ({f(s['opm_min'])}) | {f(100 * s['nt_frac'], 0)}% ({f(100 * s['nt_worst'], 0)}%) | {f(s['nt_p95'])} | "
              f"{f(s['rm_mean'])} / {f(s['rm_p95'])} / {f(s['rm_max'])} | {s['stuck']} | {s['live_max']} ({pl * 5 + 10}) | {s['biomes']} | "
              f"{s['seen']} / {s['seen_strict']} | {f(s['fade_view'])} | {f(s['gap'])} | {s['ahead_min']} | {f(s['recycles'], 0)} |")
    w("")
    # 2a. Proposed fixes (not in SS_Ride today)
    w("#### Proposed fixes vs today's algorithm, pool 25 / ahead 700 (`normal` | `greedy`)\n")
    w("Fix flags: `yield` = a creature pushed by the ridden one steps aside and anything faster pulls out from behind it; "
      "`drop` = past its own biome a creature eases to that x its tier; `clear` = RecycleClear (behind) 120 -> 60; "
      "`fb` = FrontBand 250 -> 400 (respawns ahead spread over r+300..r+700).\n")
    w("| variant | policy | total s | opps/min | no-target share / p95 s | live max | biomes | native avg / @+250 | in view BOT / strict | min gap |")
    w("|---|---|---|---|---|---|---|---|---|---|")
    for label, kw in FIX_VARIANTS:
        for pol in ("normal", "greedy"):
            s = run_summary(runs_for(seeds, policy=pol, **kw))
            w(f"| {label} | {pol} | {f(s['total'])} | {f(s['opm'])} | {f(100 * s['nt_frac'], 0)}% / {f(s['nt_p95'])} | {s['live_max']} | {s['biomes']} | "
              f"{f(100 * s['native'], 0)}% / {f(100 * s['native_b'], 0)}% | {s['seen']} / {s['seen_strict']} | {f(s['gap'])} |")
    w("")
    w("#### Sweep with the recommended fix set (yield + drop 0.7 + clear 60 + fb = Ahead - 300), policy `normal` | `greedy`\n")
    w("| pool | ahead | policy | opps/min (worst sec) | no-target share (worst sec) / p95 s | remount mean / max s | live max (cap) | biomes | native avg / @+250 | in view BOT / strict |")
    w("|---|---|---|---|---|---|---|---|---|---|")
    for pl in (3, 5, 7):
        for ah in (500, 700, 900):
            for pol in ("normal", "greedy"):
                s = run_summary(runs_for(seeds, policy=pol, per_lane=pl, ahead=ah, front_band=ah - 300, **FIX))
                w(f"| {pl * 5} | {ah} | {pol} | {f(s['opm'])} ({f(s['opm_min'])}) | {f(100 * s['nt_frac'], 0)}% ({f(100 * s['nt_worst'], 0)}%) / {f(s['nt_p95'])} | "
                  f"{f(s['rm_mean'])} / {f(s['rm_max'])} | {s['live_max']} ({pl * 5 + 10}) | {s['biomes']} | {f(100 * s['native'], 0)}% / {f(100 * s['native_b'], 0)}% | "
                  f"{s['seen']} / {s['seen_strict']} |")
    w("")
    w("#### Per-section density (fix set, fb = Ahead - 300), policy `normal`: opps/min and no-target share in sections 1 / 2 / 3 / 10\n")
    w("| variant | opps/min s1 / s2 / s3 / s10 | no-target share s1 / s2 / s3 / s10 | no-target p95 s (run) | live max | in view strict | total s |")
    w("|---|---|---|---|---|---|---|")
    for label, kw in DENSITY_VARIANTS:
        kw = dict(FIX, **kw)
        kw.setdefault("front_band", kw.get("ahead", 700) - 300)
        s = run_summary(runs_for(seeds, policy="normal", **kw))
        R = s["rows"]
        w(f"| {label} | " + " / ".join(f(R[i]["opm"]) for i in (0, 1, 2, 9)) + " | "
          + " / ".join(f(100 * R[i]["nt_frac"], 0) + "%" for i in (0, 1, 2, 9))
          + f" | {f(s['nt_p95'])} | {s['live_max']} | {s['seen_strict']} | {f(s['total'])} |")
    w("")
    rows = run_summary(runs_for(seeds, policy="normal", front_band=400, **FIX))["rows"]
    w(section_table(rows, "Recommended fix set, pool 25, ahead 700, fb 400, policy `normal`"))
    w("")
    # 2b. Remount stress: high fail rate, per section
    rs = run_summary(runs_for(seeds, policy="casual", p_fail=0.5, casual_rate=0.6))
    w("#### Remount stress (policy `casual`, p_fail 0.5), baseline pool, per section\n")
    w("| Sec | fails | remount mean / p95 / max s | stuck (>60 s) |")
    w("|---|---|---|---|")
    for r in rs["rows"]:
        w(f"| {r['k']} | {r['rm_n']} | {f(r['rm_mean'])} / {f(r['rm_p95'])} / {f(r['rm_max'])} | {r['stuck']} |")
    w("")
    for pl in (3, 7):
        s = run_summary(runs_for(seeds, policy="casual", p_fail=0.5, casual_rate=0.6, per_lane=pl))
        w(f"Remount stress with pool {pl * 5}: mean {f(s['rm_mean'])} / p95 {f(s['rm_p95'])} / max {f(s['rm_max'])} s, stuck {s['stuck']}.\n")
    # 3. Respawn distance (ViewDist) vs strict visibility
    w("#### Respawn distance (Pool.ViewDist = nearest respawn ahead) vs true visibility, policy `fast`\n")
    w("| ViewDist | strict vis | in view BOT / strict | fades in view /run | opps/min | no-target share |")
    w("|---|---|---|---|---|---|")
    for vd in (300, 400, 500):
        for vis in (450, 600):
            s = run_summary(runs_for(seeds, policy="fast", view_dist=vd, vis=vis))
            w(f"| {vd} | {vis} | {s['seen']} / {s['seen_strict']} | {f(s['fade_view'])} | {f(s['opm'])} | {f(100 * s['nt_frac'], 0)}% |")
    w("")
    # 4. Rare multiplier
    w("#### Rare multiplier (`Zones[k].Rare`, scales every extra's Weight), policy `greedy`\n")
    w("| Rare on | mult | rare seen / reachable / ridden per run | flyer seen / reachable / ridden per run | total s |")
    w("|---|---|---|---|---|")
    for zones, label in ((None, "all"), ([6, 10], "6, 10")):
        for m in (1.0, 2.0, 4.0):
            if zones and m == 1.0:
                continue
            s = run_summary(runs_for(seeds, policy="greedy", rare=m, rare_zones=zones))
            w(f"| {label} | {m:g} | {f(s['rare_seen'])} / {f(s['rare_reach'])} / {f(s['rare_rides'])} | "
              f"{f(s['fly_seen'])} / {f(s['fly_reach'])} / {f(s['fly_rides'])} | {f(s['total'])} |")
    w("")
    text = "\n".join(L)
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(text)
    print(text)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run", help="one config, per-section table")
    d = args_for()
    for name, val in vars(d).items():
        if name == "yield_":
            r.add_argument("--yield", dest="yield_", action="store_true", help="proposed fix: pushed/blocked creatures yield")
            continue
        if name == "per_lane_sec":
            r.add_argument("--per-lane-sec", type=lambda t: [int(x) for x in t.split(",")], default=None,
                           help="PerLane per section, e.g. 7,7,6,6,5,5,5,5,4,4 (proposed)")
            continue
        if name in ("view_dist_sec", "recycle_ahead_sec", "readable_sec"):
            r.add_argument("--" + name.replace("_", "-"), type=lambda t: [float(x) for x in t.split(",")], default=None,
                           help="per section (10 values), from the P4 fog table")
            continue
        if name == "rare_zones":
            r.add_argument("--rare-zones", type=int, nargs="*", default=None, help="sections (1-10) that get --rare")
            continue
        r.add_argument("--" + name.replace("_", "-"), type=type(val), default=val)
    r.add_argument("--seeds", type=int, default=1, help="runs (seed, seed+1, ...)")
    # ten-d defaults ARE the src pool (P4), so a bare `ten-d` reproduces the BOT's 10d; --p2 gives the P2-P3 pool
    t = sub.add_parser("ten-d", help="BOT 10d window per run (s2+300 -> s4+300, tier 1, no swaps); defaults = src")
    src = dict(yield_=True, straggler_drop=0.15, recycle_clear=60.0, per_lane_sec=SRC_HERD, ahead=float(P4_AHEAD),
               front_band=None, view_dist_sec=P4_VIEW, recycle_ahead_sec=P4_VIEW, quota_natives=True, far_fade=P4_FAR_FADE)
    lst = lambda conv: (lambda x: [conv(v) for v in x.split(",")])
    for name, val in vars(d).items():
        if name in ("yield_", "per_lane_sec", "rare_zones", "view_dist_sec", "recycle_ahead_sec", "front_band", "quota_natives",
                    "readable_sec"):
            continue
        t.add_argument("--" + name.replace("_", "-"), type=type(val), default=src.get(name, val))
    t.add_argument("--no-yield", dest="yield_", action="store_false", default=True)
    t.add_argument("--per-lane-sec", type=lst(int), default=SRC_HERD)
    t.add_argument("--view-dist-sec", type=lst(float), default=P4_VIEW)
    t.add_argument("--recycle-ahead-sec", type=lst(float), default=P4_VIEW)
    t.add_argument("--front-band", type=float, default=None, help="default None: respawns ahead anywhere past ViewDist (src)")
    t.add_argument("--no-quota-natives", dest="quota_natives", action="store_false", default=True)
    t.add_argument("--readable-sec", type=lst(float), default=P4_READ)
    t.add_argument("--p2", action="store_true", help="P2-P3 pool: ViewDist 300, RecycleAhead 250, Ahead 700, FrontBand 400, no on-foot quota fix")
    t.add_argument("--seeds", type=int, default=16)
    rp = sub.add_parser("report", help="all experiments -> markdown")
    rp.add_argument("--seeds", type=int, default=4)
    rp.add_argument("--out", default="sim_results.md")
    a = ap.parse_args(argv)
    if a.cmd == "report":
        report(a.out, a.seeds)
        return
    if a.cmd == "ten-d":
        if a.p2:
            a.view_dist_sec = a.recycle_ahead_sec = None
            a.ahead, a.front_band, a.recycle_ahead, a.quota_natives, a.far_fade = 700.0, 400.0, 250.0, False, 0.0
        kw = {k: v for k, v in vars(a).items() if k not in ("cmd", "seeds", "seed", "p2")}
        rs = [Sim(args_for(seed=a.seed + i, **kw)).run_10d() for i in range(a.seeds)]
        print("seed | s | empty % | longest s | in view | fast pops | no target % | longest s | ahead mean | live (cap) | stragglers avg / max %")
        for i, x in enumerate(rs):
            print(f"{a.seed + i} | {x['time']:.0f}{'' if x['reached'] else ' NR'} | {100 * x['empty']:.1f} | {x['empty_long']:.1f} | {x['seen']} | {x['fast_pops']} | "
                  f"{100 * x['nt']:.0f} | {x['nt_long']:.1f} | {x['ahead_mean']:.1f} | {x['live']} ({x['cap']}) | {100 * x['str_avg']:.0f} / {100 * x['str_max']:.0f}")
        fail = [i for i, x in enumerate(rs) if x["empty"] > 0.10 or x["empty_long"] > 8 or x["seen"] > 0 or x["nt"] > 0.25
                or x["nt_long"] > 12 or x["ahead_mean"] < 5 or not x["reached"] or x["live"] > x["cap"] or x["str_avg"] > 0.25
                or x["fast_pops"] > 0]
        print(f"WORST empty {100 * max(x['empty'] for x in rs):.1f}% / {max(x['empty_long'] for x in rs):.1f} s; in view {max(x['seen'] for x in rs)}; "
              f"fast pops in readable band {max(x['fast_pops'] for x in rs)}; "
              f"no target {100 * max(x['nt'] for x in rs):.0f}% / {max(x['nt_long'] for x in rs):.1f} s; ahead mean min {min(x['ahead_mean'] for x in rs):.1f}; "
              f"live max {max(x['live'] for x in rs)} (cap {rs[0]['cap']}); stragglers avg max {100 * max(x['str_avg'] for x in rs):.0f}%; "
              f"runs failing BOT 10d limits: {len(fail)}/{len(rs)}")
        return
    kw = {k: v for k, v in vars(a).items() if k not in ("cmd", "seeds", "seed")}
    runs = [Sim(args_for(seed=a.seed + i, **kw)).run() for i in range(a.seeds)]
    s = run_summary(runs)
    print(section_table(s["rows"], f"policy {a.policy}, pool {a.per_lane * 5}, ahead {a.ahead}, seeds {a.seed}..{a.seed + a.seeds - 1}"))
    print(f"\nends {s['ends']}; total {f(s['total'])} s; opps/min {f(s['opm'])}; no-target {f(100 * s['nt_frac'], 0)}% p95 {f(s['nt_p95'])} s; "
          f"remount mean {f(s['rm_mean'])} p95 {f(s['rm_p95'])} max {f(s['rm_max'])} stuck {s['stuck']}; live max {s['live_max']}; "
          f"native {f(100 * s['native'], 0)}% (@+250 {f(100 * s['native_b'], 0)}%, worst run {f(100 * s['native_bmin'], 0)}%); biomes {s['biomes']}; seen {s['seen']}/{s['seen_strict']}; fades in view/run {f(s['fade_view'], 0)}; rare seen/reach/ride {f(s['rare_seen'])}/{f(s['rare_reach'])}/{f(s['rare_rides'])}; "
          f"flyer {f(s['fly_seen'])}/{f(s['fly_reach'])}/{f(s['fly_rides'])}")


if __name__ == "__main__":
    main()
