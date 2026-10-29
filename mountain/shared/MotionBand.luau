-- Band one-shots (owner 2026-10-28, plan §22, P7 G): the keyframes of every mountain transient that animates in the top band
-- (banner, carry pop-up, RUN! word / pill / ring, moment title / sub / Collect). Pure, so mountain/tests/motion_band.luau samples
-- the very keys the client plays; client/UI/Motion.luau wraps them into Motion.tokens (kind, pivot, follow, the Instance reads).
-- Timing and shapes = intel §6 (the P6 tokens); only amplitudes / pivots changed, each named "P7 §22".
-- Rule: a piece's animated extent (box + its decor) never reaches below its static bottom. P.bandSlot seats every band box to end
-- at M's top at the latest, so no band one-shot enters M at any size. Units = the piece's own px (o.Size offsets): each holder
-- UIScale multiplies sizes, offsets and lifts alike, so one check per piece covers all six sizes.
local B={}
-- Easing (pure twins of Motion's M.ease map, for sampling only): out Quad Out, inOut Sine InOut, ease Sine Out, linear,
-- quint Quint Out, back Back Out.
B.ease={
 out=function(t) return 1-(1-t)^2 end,inOut=function(t) return -(math.cos(math.pi*t)-1)/2 end,ease=function(t) return math.sin(t*math.pi/2) end,
 linear=function(t) return t end,quint=function(t) return 1-(1-t)^5 end,
 back=function(t) local c1=1.70158;return 1+(c1+1)*(t-1)^3+c1*(t-1)^2 end,
}
-- Channel tracks from keys (time, a/s/x/y/r, optional per-key easing e): the one builder Motion's engine also uses.
local CH={'a','s','x','y','r'}
function B.tracks(keys,ease)
 local tr={}
 for _,c in ipairs(CH) do
  local pts={};for _,k in ipairs(keys) do if k[c]~=nil then table.insert(pts,{k[1],k[c],k.e or ease or 'out'}) end end
  if #pts>0 then tr[c]=pts end
 end
 return tr
end
function B.at(pts,t)
 if t<=pts[1][1] then return pts[1][2] end
 for i=1,#pts-1 do local p,q=pts[i],pts[i+1];if t<q[1] then return p[2]+(q[2]-p[2])*B.ease[p[3]]((t-p[1])/(q[1]-p[1])) end end
 return pts[#pts][2]
end
-- How far a w x h box reaches below its static bottom (px; > 0 = lower) at scale s about the pivot (.5, py), rotated r° about
-- its centre (Roblox GuiObject rotation) and moved y. Decor reaching e past every edge (W.glow (1,2e) at -e; a lip counts as
-- e = its drop, conservative) is measured against its own static bottom, or with strict against the box bottom (RUN! ring).
function B.dip(s,r,y,w,h,e,py,strict)
 local a=math.rad(r or 0);local sn,cs=math.abs(math.sin(a)),math.abs(math.cos(a))
 local c=py*h*(1-s)+y+h*s/2 -- scaled, moved centre (static top = 0)
 local box=c+s*(w*sn+h*cs)/2-h
 if e<=0 then return box end
 return math.max(box,c+s*((w+2*e)*sn+(h+2*e)*cs)/2-h-(if strict then 0 else e))
end
-- Worst dip of a spec over its whole timeline (1/480 s steps), and the channels at a time (tests).
function B.state(tr,t) return {a=tr.a and B.at(tr.a,t),s=if tr.s then B.at(tr.s,t) else 1,x=if tr.x then B.at(tr.x,t) else 0,y=if tr.y then B.at(tr.y,t) else 0,r=if tr.r then B.at(tr.r,t) else 0} end
function B.worst(sp,w,h,e,k)
 local tr=B.tracks(sp.keys(w,h,e,k),sp.ease);local n=math.ceil(sp.dur*480);local worst,at=-math.huge,0
 for i=0,n do local t=sp.dur*i/n;local v=B.state(tr,t);local d=B.dip(v.s,v.r,v.y,w,h,e,sp.py,sp.strict);if d>worst then worst,at=d,t end end
 return worst,at
end

local M=.5 -- margin px under a tilt (sin / cos are not linear between keys)
-- RUN! word (L165) and its RunDrop (same channels). P7 §22: pivot = the word's bottom edge (py 1), so the 3.4 slam, the 1.1
-- overshoot and the 1.12 exit grow up / off the screen top instead of down into M (was centre: 3.4 reached 104 px into M at
-- 844x390). The tilt still dips a lower corner by s(w|sin r| + h(|cos r|-1))/2, so y lifts cancel it: y0 at the 3.4 start, L1
-- on the .25 / .4 overshoots, L2 under the camera-shake wobble (the ±2 px vertical beat kept around the lifted line; the word
-- drops back to rest at .95). k = 0 (cameraShake off): no wobble, L2 = 0. Decor e (none on the word today) lifts the exit too.
local function slam(w,h,e,k)
 local function d(s,r) return B.dip(s,r,0,w,h,e,1) end
 local L1=math.max(d(.86,2),d(1.1,-1.5),0)+M
 local L2=if k>0 then math.max(d(1,-k)+2*k,d(1,k)-2*k,0)+M else 0
 local y0=-math.max(d(3.4,-8)+M,L1)
 return {{0,a=0,s=3.4,r=-8,x=0,y=y0},{.1,a=1},{.25,s=.86,r=2,y=-L1},{.4,s=1.1,r=-1.5,y=-L1},{.5,s=1,r=0,x=0,y=-L2},
  {.65,x=-4*k,y=2*k-L2,r=-k},{.8,x=4*k,y=-2*k-L2,r=k},{.95,x=0,y=0,r=0},{1.3,a=1,s=1,y=0},{1.5,a=0,s=1.12,r=0,x=0,y=-.12*e}}
end
-- "<GUARDIAN> IS AWAKE" pill (L166). P7 §22: the y +8 entry (dipped ~4 px into M on the low row) becomes x -6 = the 6 px gap
-- to the word, so the pill slides out of the word's side, never over the word and away from the coin pill.
local function awake() return {{0,a=0,x=-6},{.3,a=0,x=-6},{.5,a=1,x=0},{1.3,a=1},{1.5,a=0,x=0}} end
-- RUN! shock ring (L168, a burst). P7 §22: pivot = the ring's bottom (py 1) and y = -e x s, so the drawn ring and its glow (e)
-- never pass the ring's static bottom (<= M's top, P.bandShock): the .2 -> 2.6 burst rises from the word's base as a dome
-- instead of spreading down through M (was centre: 2.6 reached ~70 px into M at 844x390).
local function shock(_,_,e) return {{0,a=0,s=.2,y=-.2*e},{.2,a=0,s=.2,y=-.2*e},{.25,a=.9},{1,a=0,s=2.6,y=-2.6*e}} end
-- Tier-2 banner (L147-148). P7 §22: pivot bottom (py 1); the 1.05 overshoot lifts y by its glow growth (-.05 e), so the glow too
-- stays at its static extent. Entry / exit y -30 unchanged (upward).
local function banner(_,_,e) return {{0,a=0,y=-30,s=.8},{.25,a=1,y=-.05*e,s=1.05},{.4,s=1,y=0},{2.1,a=1,y=0},{2.5,a=0,y=-30,s=1}} end
-- Moment title + sub pill (L152-153; the title's drop label follows). P7 §22: pivot bottom (py 1), so the 2.4 entry grows up off
-- the top and the 1.08 exit grows up (was centre: 2.4 reached ~22 px into M at 844x390, the sub pill .7 px); y = -(s-1) e for
-- decor while s > 1.
local function moment(_,_,e) return {{0,a=0,s=2.4,y=-1.4*e},{.3,a=1,s=.94,y=0},{.45,s=1},{2.05,a=1,s=1,y=0},{2.5,a=0,s=1.08,y=-.08*e}} end
-- Sanctuary moment Collect (W.cta, a touch target that may sit just below M). P7 §22: no growth past its box at all, centre
-- pivot, s .9 -> 1 on the moment's in timing (was the moment's 2.4 about its centre: +32 px each way, into M from above or below);
-- the out never plays (held).
local function collect() return {{0,a=0,s=.9},{.3,a=1},{.45,s=1},{2.05,a=1,s=1},{2.5,a=0,s=1}} end
-- Carry pop-up (B.cpop, board text timing in at .35 s). P7 §22 (owner): no flight to the portrait through the centre; it shrinks
-- and fades in place (centre pivot): s .45 a .9 at 2.3 s, s 0 a 0 at 2.5 s (the L686 window), while carry.portraitIn pops the
-- portrait by the dock (unchanged, 2.34 -> 2.6 s). The 1.08 overshoot (2.9 px into M at 749x330) lifts y by its growth below
-- the centre, -(.08)(h/2 + e), so box and glow stay at their static extent.
local function carryPop(_,h,e) return {{0,a=0,y=-24,s=.5},{.25,a=1,y=-.08*(h/2+e),s=1.08},{.35,s=1,y=0},{2.0,a=1,y=0,s=1},{2.3,a=.9,s=.45},{2.5,a=0,s=0}} end

-- Specs: dur / ease / inEnd = intel §6 (unchanged); py = scale pivot (AnchorPoint Y, X .5); strict = decor measured against
-- the box. keys(w, h, e, k): w,h = the piece's own box, e = its decor reach, k = 1 camera shake on / 0 off.
B.spec={
 banner={dur=2.5,ease='out',inEnd=.4,py=1,keys=banner},
 moment={dur=2.5,ease='out',inEnd=.45,py=1,keys=moment},
 ['moment.collect']={dur=2.5,ease='out',inEnd=.45,py=.5,keys=collect},
 ['carry.pop']={dur=2.5,ease='out',inEnd=.35,py=.5,keys=carryPop},
 ['run.slam']={dur=1.5,ease='inOut',inEnd=.95,py=1,keys=slam},
 ['run.awake']={dur=1.5,ease='inOut',inEnd=.5,py=.5,keys=awake},
 ['run.shock']={dur=1,ease='out',py=1,strict=true,keys=shock},
}
return B
