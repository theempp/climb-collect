-- Glassbloom motion (P6): the one motion-tokens module and the only TweenService user. Values: climb&collect/design/
-- hud-glassbloom-intel.md §6 (L### = design/hud-board-v3/index.html lines), the P6 brief (owner answers plan §19; board text
-- timings win over the CSS, plan §12). Builders leave each piece in its static end state tagged Motion=<token>; Motion plays on
-- top and hands the piece back in that state. Two engines: loops = real Tweens, gated by visibility, the cover rule and the
-- plan §6 budget; one-shots = a keyframe timeline (alpha/scale/x/y/rot, per-segment easing) on one RenderStepped connection
-- that exists only while a one-shot plays. Requires Theme + MountainShared.MotionBand (Widgets will require Motion).
-- P7 G (owner, plan §22): the band one-shots' keys come from MotionBand (pure, CLI-sampled) and never reach below their static
-- bottom, so nothing animates into the keep-clear centre M; Motion.tokens is still the one table every caller reads.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local TS=game:GetService('TweenService')
local TextService=game:GetService('TextService')
local T=require(script.Parent.Theme)
local Band=require(RS.MountainShared.MotionBand)
local M={}
local S,D=Enum.EasingStyle,Enum.EasingDirection
-- Easing map (brief): CSS ease-out → Quad Out · ease-in-out → Sine InOut · default `ease` → Sine Out · linear · cubic-bezier
-- (.14,.64,.2,1) → Quint Out · (.2,1.4,.4,1) / (.2,1.5,.4,1) → Back Out. Keyframe easing applies per segment (between keys).
local E={out={S.Quad,D.Out},inOut={S.Sine,D.InOut},ease={S.Sine,D.Out},linear={S.Linear,D.Out},quint={S.Quint,D.Out},back={S.Back,D.Out}}
M.ease=E
local MID=Vector2.new(.5,.5);local ZERO=UDim2.new()
local weak={__mode='k'}

-- The HUD CarryPortrait (carry.portraitIn starts with the pop-up; P7 §22: the pop-up no longer flies to it).
local function portraitOf(o) local layer=o:FindFirstAncestor('Hud');return layer and layer:FindFirstChild('CarryPortrait') end
local function sibling(suffixOf,pos) return function(o) local d=o.Parent and o.Parent:FindFirstChild(suffixOf(o));return if d then {d,pos} else nil end end
-- Decor reach (MotionBand e): how far o's direct children (W.glow (1,2e) at -e, a lip +5) reach below its box, o's own px.
local function reach(o)
 local h=o.Size.Y.Offset;local e=0
 for _,c in ipairs(o:GetChildren()) do
  if c:IsA('GuiObject') and c.Visible then local sz=c.Size.Y.Scale*h+c.Size.Y.Offset;e=math.max(e,c.Position.Y.Scale*h+c.Position.Y.Offset+(1-c.AnchorPoint.Y)*sz-h) end
 end
 return e
end
-- A band one-shot (P7 §22): MotionBand's spec (dur / ease / inEnd / pivot / keys from the piece's own box and decor) + extras.
local function band(name,extra)
 local b=Band.spec[name]
 local tk={kind='shot',dur=b.dur,ease=b.ease,inEnd=b.inEnd,pivot=Vector2.new(.5,b.py),keys=function(o)
  return b.keys(o.Size.X.Offset,o.Size.Y.Offset,reach(o),if (T.prefs or {}).cameraShake==false then 0 else 1) end}
 for k,v in pairs(extra or {}) do tk[k]=v end
 return tk
end

-- Tokens. kind: shot (keys = {t, a=alpha, s=scale, x/y=offset px, r=rot°}, or keys(o); inEnd = end of the in part, played alone
-- under MotionHold; pivot = the scale's AnchorPoint, default centre) · show (show/hide shots) · tween (Motion.to / Motion.value)
-- · loop (to/rev, or steps; cat = plan §6 budget) · hold (a timer) · mark / timeline (reveal, Task C). Durations in s; ease = a
-- key of M.ease. Band one-shots (banner, moment, carry.pop, run.*): band() = MotionBand.spec (P7 §22 amplitudes named there).
M.tokens={
 -- Tier messages (§4). Lifetimes stay in HudState/Feedback; each one-shot ends inside them.
 -- Toast (top right, clear of M by its width cap): y -8 up, x +16 toward the screen edge, both away from M (P7 §22 checked).
 toast={kind='shot',dur=1.5,ease='out',inEnd=.225,keys={{0,a=0,x=0,y=-8},{.225,a=1,y=0},{1.17,a=1,x=0},{1.5,a=0,x=16,y=0}}}, -- L142-143 (15 %/78 %)
 banner=band('banner'), -- L147-148 (10/16/84 %)
 ['banner.danger']={kind='alias',of={'run.slam','run.awake','run.shock'}}, -- RUN! is the danger banner (L415)
 -- Moment (L152-153, 12/18/82 %): the title's drop label (Position-synced by Feedback) follows scale/alpha. Title + sub pill.
 moment=band('moment',{follow=sibling(function(o) return o.Name..'Drop' end,false)}),
 -- The moment's sanctuary Collect (HudPiece collect, Motion='moment'): no growth past its box (P7 §22; it may sit below M).
 ['moment.collect']=band('moment.collect'),
 -- The legacy reward modal (F:reveal Dialog, Motion='moment', no HudPiece): a shaded, player-dismissed dialog like the player
 -- card, exempt from M; keeps the P6 centre pop (intel §6 moment keys).
 ['moment.modal']={kind='shot',dur=2.5,ease='out',inEnd=.45,keys={{0,a=0,s=2.4},{.3,a=1,s=.94},{.45,s=1},{2.05,a=1,s=1},{2.5,a=0,s=1.08}}},
 -- Carry pop-up, board text timing (in at .35 s, plan §12 / G4); P7 §22: shrinks and fades in place (no flight to the portrait).
 ['carry.pop']=band('carry.pop'),
 -- L687 WAAPI keys (default linear): scale 0 until .9 → 1.3 at .96 → 1 of 2.6 s; opacity 0 → 1 on the same keys.
 ['carry.portraitIn']={kind='shot',dur=2.6,ease='linear',keys={{0,a=0,s=0},{2.34,a=0,s=0},{2.496,a=1,s=1.3},{2.6,a=1,s=1}}},
 ['carry.iconTwist']={kind='shot',dur=.45,ease='linear',inEnd=.45,keys={{0,r=-14,s=.7},{.25,r=8,s=1.15},{.45,r=0,s=1}}}, -- L688 (.1/.18 of 2.5 s)
 -- RUN! (L165 at 1.5 s = the first 30 % of the 5 s demo): RunDrop follows every channel. Shake keys (.65/.8 s) zero with
 -- cameraShake off. P7 §22: word + ring pivot on their bottom edge, the pill slides out of the word's side (MotionBand).
 ['run.slam']=band('run.slam',{follow=sibling(function() return 'RunDrop' end,true)}),
 ['run.awake']=band('run.awake'), -- L166
 ['run.shock']=band('run.shock'), -- L168; a burst: held = played whole
 -- HUD state transitions.
 xpLine={kind='shot',dur=1.5,ease='out',inEnd=.18,keys={{0,a=0},{.18,a=1},{1.125,a=1},{1.5,a=0}}}, -- L120 on the board-text 1.5 s (12/75 %)
 ['xpLine.fill']={kind='tween',dur=.675,delay=.225,ease='out'}, -- L121 15 %→60 % of 1.5 s
 xpRing={kind='tween',dur=.675,delay=.225,ease='out'}, -- derived: dock + card rings tween over the xpLine fill window
 ['dock.chaseFade']={kind='tween',dur=.2,ease='ease',reducedFade=true}, -- L134 transition opacity .2s
 ['dock.tapRestore']={kind='hold',hold=3}, -- L414/L670
 ['rail.idle']={kind='hold',hold=3}, -- L416 board text; the timer is Hud:checkpoint's HudState duration
 ['rail.bright']={kind='tween',dur=.49,out=.56,ease='inOut',reducedFade=true}, -- L107 railcp 55→62 %, 82→90 % of 7 s
 ['rail.label']={kind='show',show={dur=.49,ease='inOut',keys={{0,a=0,x=-6},{.49,a=1,x=0}}},hide={dur=.56,ease='inOut',keys={{0,a=1},{.56,a=0}}}}, -- L109
 ['pcard.open']={kind='show',show={dur=.2,ease='out',keys={{0,a=0,x=-115,y=40},{.2,a=1,x=0,y=0}}}}, -- L138/L171 as rendered (§19, G23); hide instant
 ['edge.nudge']={kind='loop',cat='hud',dur=.5,ease='inOut',to={x=-4},rev=true}, -- L130 nudge 1 s (50 % key)
 ['vignette.pulse']={kind='loop',cat='hud',dur=.55,ease='inOut',to={a=.45},rev=true}, -- L69/L139 vigp 1.1 s
 -- Menus / shop (Task B wires these).
 -- Panel open (§19: fade + scale .96 → 1, .2 s ease-out) = two shots with the same timing: the fade on HubShade (the tint and
 -- everything in it, so the Hub fades once) and the scale on the Hub.
 -- hush: loops inside wait until it lands (an alpha loop started mid-fade would keep a half-faded base).
 ['panel.open']={kind='shot',dur=.2,ease='out',hush=true,keys={{0,a=0},{.2,a=1}}},
 ['panel.scale']={kind='shot',dur=.2,ease='out',keys={{0,s=.96},{.2,s=1}}},
 ['panel.close']={kind='shot',dur=.15,ease='linear',keys={{0,a=1},{.15,a=0}}}, -- §19 .15 s fade (no easing given: linear)
 ['tab.scroll']={kind='tween',dur=.3,ease='out'}, -- §19
 ['hero.mini']={kind='tween',dur=.2,ease='out'}, -- §19: hero height full ↔ mini
 ['hero.fade']={kind='shot',dur=.2,ease='out',keys={{0,a=0},{.2,a=1}}}, -- §19: the hero's Inner contents fade in with the glide
 ['tog.knob']={kind='tween',dur=.15,ease='ease'}, -- L322 left .15s, x 3 ↔ 29
 ['rays.panel']={kind='loop',cat='rays',dur=40,ease='linear',to={r=360}}, -- L212
 ['rays.hero']={kind='loop',cat='rays',dur=24,ease='linear',to={r=360}}, -- L223
 ['rays.reveal']={kind='loop',cat='rays',dur=26,ease='linear',to={r=360}}, -- L327
 holo={kind='loop',cat='holo',dur=5,ease='linear',to={xs=-2.4}}, -- L207-208: Cycle 4.8× wide, one cycle = X scale 0 → -2.4
 -- L243-244: 0-62 % rest at -40 %, sweep to 130 % in the last 38 % of 3.2 s; the first 3 visible staggered (brief).
 ['buy.shine']={kind='loop',cat='shine',stagger={0,1.07,2.13},steps={{wait=1.984},{dur=1.216,ease='inOut',to={xs=1.3}},{set={xs=-.4}}}},
 bob={kind='loop',cat='idle',dur=1.2,ease='inOut',to={y=-5},rev=true}, -- L225-227 2.4 s (MotionDelay .5 on the 2nd item)
 ['bob.pass']={kind='loop',cat='idle',dur=1.3,ease='inOut',to={y=-5},rev=true}, -- L274 2.6 s
 ['burst.wob']={kind='loop',cat='idle',dur=1,ease='inOut',to={s=1.07},rev=true}, -- L269-271 2 s
 ['egg.wobble']={kind='loop',cat='idle',steps={{wait=1.96},{dur=.168,ease='inOut',to={r=-7}},{dur=.168,ease='inOut',to={r=6}},{dur=.168,ease='inOut',to={r=-3}},{dur=.336,ease='inOut',to={r=0}}}}, -- L290-291 70/76/82/88 % of 2.8 s
 -- L300-301: translateX -80 % → 130 % of the streak's own width (70 % of the trail) = X scale -.56 → .91. Streak + swing = one slot.
 ['trail.streak']={kind='loop',cat='idle',group='parent',from={xs=-.56},dur=1.4,ease='linear',to={xs=.91}},
 ['trail.swing']={kind='loop',cat='idle',group='parent',dur=.7,ease='inOut',to={r=-18},rev=true}, -- L302-303 1.4 s
 pulse={kind='loop',cat='idle',dur=.6,ease='inOut',to={s=1.08,a=.85},rev=true}, -- L39/L253 1.2 s
 sparkle={kind='loop',cat='reveal',from={s=.4,r=0,a=.4},dur=1.1,ease='inOut',to={s=1,r=45,a=1},rev=true}, -- L41-42 2.2 s, delays .7/1.3 (MotionDelay)
 -- Hatch reveal (Task C, board L725-738 + brief). `at` = start in s from the reveal (MotionDelay adds); every piece rests in its
 -- t = 0 key until then, i.e. the pre-spin / pre-landed pose. Feedback builds the landed + named + cta end state.
 ['reveal.spin']={kind='shot',at=0,dur=3.4,ease='quint',keys={{0,x=1512},{3.4,x=0}}}, -- L733/L737: X(0)-X(14) = (422-54)-(422-1566) = 1512
 ['reveal.landed']={kind='mark',at=3.5,spinSize=T.t.revealTitle,spinTitle={rare='SOMETHING RARE IS COMING...',common='SOMETHING IS COMING...'}}, -- L738, §19 (instant)
 -- Band / track / selector are built dimmed (opacity × (1-revealDimT), Feedback dimT): undim = opacity × 1/(1-revealDimT) until
 -- landed, then back to the built dim over .4 s (L345 transition .4s, CSS default ease).
 ['reveal.dim']={kind='shot',at=0,dur=3.9,ease='ease',keys={{0,a=1/(1-T.revealDimT)},{3.5,a=1/(1-T.revealDimT)},{3.9,a=1}}},
 -- L336-337 burst: opacity 1 → 0, scale .4 → 2.8 (2nd ring MotionDelay .12). Built fully transparent: the timeline sets the opaque
 -- base (glowHalo.t, ring T 0) and the step key keeps it hidden until it starts.
 ['reveal.halo']={kind='shot',at=3.5,dur=1.1,ease='out',keys={{0,a=0,s=.4},{0,a=1,s=.4},{1.1,a=0,s=2.8}}},
 ['reveal.shard']={kind='shot',at=3.5,dur=.9,ease='out',keys={{0,a=1,s=1},{.9,a=0,s=.6}}}, -- L339-341; G12: not built
 ['reveal.cardIn']={kind='shot',at=3.65,dur=.5,ease='back',keys={{0,a=0,s=.3,r=-5},{.5,a=1,s=1,r=0}}}, -- L342-344 delay .15: rot -8 → -3 (built -3, r adds)
 -- L346-348 delay .3: scale 2.6 → 1, α 0 → 1 at y 238 (+12 on the built 226), then 238 → 226 at named (4.3 s = .5 in), instant.
 ['reveal.slam']={kind='shot',at=3.8,dur=.5,ease='back',keys={{0,a=0,s=2.6,y=12},{.4,a=1,s=1},{.5,y=12},{.5,y=0}}},
 ['reveal.name']={kind='shot',at=4.3,dur=.4,ease='ease',keys={{0,a=0,y=10},{.4,a=1,y=0}}}, -- L349-352
 ['reveal.cta']={kind='shot',at=5.7,dur=.4,ease='ease',keys={{0,a=0,y=12,s=.9},{.4,a=1,y=0,s=1}}}, -- L353-354
 -- World tokens (home-base P7, kind='world'): data only, read by WorldFx.client.luau (the one world-motion driver). No keys /
 -- dur / steps / show, so play, show, to, value, loops, scan and the reveal timeline all pass them by (they test kind / keys /
 -- dur). Beats in s of effect time from the plot's TierUpAt (WorldFx: (server now - TierUpAt) * M.speed()).
 ['world.tierup']={kind='world',endT=6.5,reducedFade=.15, -- homebase-world-style-intel §C world.tierup (hold 6.5, Reduce .15 s crossfade)
  beats={idle={0,1},anticipation={1,1.5},deconstruct={1.5,2.5},swirl={2.5,4.5},contract={4.5,5},reconstruct={5,6},hold={6,6.5}}, -- homebase-intel §D beats 1-7
  caps={high={cubes=48,orbs=10},med={cubes=24,orbs=5}},visitor=.5,visitorRange=150,rings=3, -- homebase-intel §F VFX cube pool (PLAN:76); rings: P7 brief
  -- Shape (PROPOSED, no spec source; owner check at STOP 8). Radii x half the old House footprint (max of x / z bounding size / 2).
  shape={cube=2.2,orb=1.2,ringStart=1.05,ringOrbit=1.35,ringGap=2.5,ringLine=.35,ringThick=.9,ringH=.2,ringT=.3,ringPulse=.15,
   shockFrom=.6,shockTo=2.4,cloud=1,cloudJitter=.2,cloudLow=.2,cloudHigh=.7,orbR=.7,orbLow=.55,orbHigh=.85,lift=6,
   spin=1.6,orbSpin=2.4,ringSpin=.8,tumble=2,contract=.35,lagMax=.5,wave=.5,cubeFade=.6,orbIn=.3,fill=.8},
  pulse=1.2, -- ring / orb glow period = the `pulse` token's reversing cycle (.6 s x 2, L39/L253)
  ease={widen='out',lift='inOut',shock='out',contract='inOut',settle='out',reveal='out',fade='linear'}}, -- M.ease keys; reveal / settle = entries (ease-out)
}
for k,v in pairs(M.tokens) do v.id=k;if v.show then v.show.id=k..'.show' end;if v.hide then v.hide.id=k..'.hide' end end -- stats names
local AUTO_SHOT={toast=true,banner=true,moment=true,['carry.pop']=true,['carry.iconTwist']=true,['run.slam']=true,['run.awake']=true,['run.shock']=true}
local CAPS={holo=1,shine=3,idle=6} -- plan §6, per open menu (one menu at a time; the reveal covers the rest). rays: 1 per token

-- QA time scale (evidence capture only): a playback speed, .1 = 10× slower. Honoured only while ReplicatedStorage.StudioAids
-- == true; read from ReplicatedStorage.MotionTimeScale; applies to tweens / one-shots / holds started after it changes.
M.timeScale=1
local function readScale() local v=RS:GetAttribute('MotionTimeScale');M.timeScale=if type(v)=='number' and v>0 then v else 1 end
readScale();RS:GetAttributeChangedSignal('MotionTimeScale'):Connect(readScale)
local function speed() return if RS:GetAttribute('StudioAids')==true then M.timeScale else 1 end
function M.setTimeScale(v) RS:SetAttribute('MotionTimeScale',if type(v)=='number' and v>0 then v else nil) end
-- The playback speed in force now (1 live). World effects read it once at start, the server's tier swap delay uses the same rule.
M.speed=speed
-- Eased value of u in 0..1 for a M.ease key (world drivers step their own clock; TweenService stays in this module).
function M.eased(name,u) local e=E[name or 'out'];return TS:GetValue(math.clamp(u,0,1),e[1],e[2]) end
function M.after(sec,fn) return task.delay(sec/speed(),fn) end
-- fn on a later frame than the current one, whatever phase calls it (input or Heartbeat): the second Heartbeat hop is always the
-- next frame. Keeps capture / loop work off a build frame.
function M.later(fn) Run.Heartbeat:Once(function() Run.Heartbeat:Once(fn) end) end

-- Gates (brief). Reduced: loops stop, transitions instant (or a .15 s linear fade for group-transparency state changes).
function M.reduced()
 local p=T.prefs or {};local me=Players.LocalPlayer
 return p.reducedMotion==true or p.simplifiedVFX==true or p.effectsTier==0 or (me~=nil and (me:GetAttribute('MountainReducedMotion')==true or me:GetAttribute('MountainSimplifiedVFX')==true))
end
function M.noRays() return (T.prefs or {}).effectsTier==0 end
-- World VFX caps (homebase-intel §F): effectsTier 1 (nil = default 1, UIProtocol) = high, .5 = med, 0 or reduced = none;
-- owner == false (a visitor within the token's visitorRange) gets the visitor share, floored. name defaults to world.tierup.
function M.worldCaps(owner,name)
 local tk=M.tokens[name or 'world.tierup'];local e=(T.prefs or {}).effectsTier;if type(e)~='number' then e=1 end
 local c=tk and not M.reduced() and (if e>=1 then tk.caps.high elseif e>=.5 then tk.caps.med else nil)
 if not c then return {cubes=0,orbs=0} end
 local k=if owner==false then tk.visitor else 1
 return {cubes=math.floor(c.cubes*k),orbs=math.floor(c.orbs*k)}
end

-- Tweens (stats count the ones playing).
local live={}
local function info(d,ease,rep,rev,delay) local e=E[ease or 'out'];local k=speed();return TweenInfo.new(d/k,e[1],e[2],rep or 0,rev==true,(delay or 0)/k) end
local function mk(o,ti,goal,done)
 local tw=TS:Create(o,ti,goal)
 tw.Completed:Connect(function(state) live[tw]=nil;if done then done(state) end end)
 return tw
end
local function play(tw) live[tw]=true;tw:Play() end

-- Alpha = opacity multiplier over the piece + descendants, from their values at start (fully transparent ones are skipped).
-- prune (one-shots): skip hidden subtrees and scroll children outside their window — nothing there shows during a short fade
-- (Studio P6 C: the Shop open fade captured ~1,250 instances; most sit below the fold).
local function snap(o,list,prune)
 local function add(x,k) local v=x[k];if v<1 then table.insert(list,{x,k,v}) end end
 local function one(x)
  if x:IsA('UIStroke') then add(x,'Transparency')
  elseif x:IsA('GuiObject') then
   add(x,'BackgroundTransparency')
   if x:IsA('TextLabel') or x:IsA('TextButton') or x:IsA('TextBox') then add(x,'TextTransparency');add(x,'TextStrokeTransparency')
   elseif x:IsA('ImageLabel') or x:IsA('ImageButton') then add(x,'ImageTransparency') end
  end
 end
 if not prune then one(o);for _,x in ipairs(o:GetDescendants()) do one(x) end;return list end
 local function walk(x)
  one(x)
  local y0,y1
  if x:IsA('ScrollingFrame') then local p,s=x.AbsolutePosition,x.AbsoluteSize;y0,y1=p.Y,p.Y+s.Y end
  for _,c in ipairs(x:GetChildren()) do
   if not c:IsA('GuiObject') then if c:IsA('UIStroke') then one(c) end
   elseif c.Visible then
    if not y0 then walk(c) else local a,b=c.AbsolutePosition.Y,c.AbsoluteSize.Y;if a+b>y0 and a<y1 then walk(c) end end
   end
  end
 end
 walk(o);return list
end
local function fade(list,a) for _,v in ipairs(list) do v[1][v[2]]=math.max(0,1-(1-v[3])*a) end end -- a > 1: undim, Back overshoot
-- Scale pivot pv (default centre; P7 §22 band pieces: bottom edge): AnchorPoint pv and Position shifted by (pv - anchor) * Size;
-- scale = a Motion-owned UIScale.
local function shiftOf(sz,ap,pv) pv=pv or MID;local ax,ay=pv.X-ap.X,pv.Y-ap.Y;return UDim2.new(ax*sz.X.Scale,ax*sz.X.Offset,ay*sz.Y.Scale,ay*sz.Y.Offset) end
local scalers=setmetatable({},weak) -- live MotionScale UIScales -> host (Widgets skips size refits under them)
local function scaler(o) local u=o:FindFirstChild('MotionScale');if not (u and u:IsA('UIScale')) then u=Instance.new('UIScale');u.Name='MotionScale';u.Parent=o end;scalers[u]=o;return u end
local function dropScale(u)
 local host=scalers[u];scalers[u]=nil;u:Destroy()
 if host and M.scaleDone then M.scaleDone(host) end -- Widgets refits the labels whose size changed meanwhile
end
-- Widgets (W.fit): a MotionScale is live somewhere; label-under-scale checks are skipped otherwise.
function M.scaling() return next(scalers)~=nil end

-- One-shot engine. Position is driven as an offset on top of the base; a write from outside (layout) becomes the new base.
local tracks=Band.tracks -- the same track builder the CLI samples (mountain/tests/motion_band.luau)
local function at(pts,t)
 if t<=pts[1][1] then return pts[1][2] end
 for i=1,#pts-1 do
  local p,q=pts[i],pts[i+1]
  if t<q[1] then local e=E[p[3]];return p[2]+(q[2]-p[2])*TS:GetValue((t-p[1])/(q[1]-p[1]),e[1],e[2]) end
 end
 return pts[#pts][2]
end
local shots={} -- GuiObject -> playing one-shot
local beat
local markDirty -- loop re-check (below); a hush shot ending re-checks the loops it held
-- Our own last write read back (tolerant of a float32 Scale round-trip); anything else is a layout write = the new base.
local function same(p,q) return p.X.Offset==q.X.Offset and p.Y.Offset==q.Y.Offset and math.abs(p.X.Scale-q.X.Scale)<1e-4 and math.abs(p.Y.Scale-q.Y.Scale)<1e-4 end
local function apply(s,t)
 local tr=s.tr
 local a=if tr.a then at(tr.a,t) else nil;local sc=if tr.s then at(tr.s,t) else nil
 local x=if tr.x then at(tr.x,t) else 0;local y=if tr.y then at(tr.y,t) else 0;local r=if tr.r then at(tr.r,t) else 0
 if a and a~=s.a then fade(s.alpha,a) end -- held keys (reveal undim 0-3.5 s) write nothing
 for _,g in ipairs(s.targets) do
  local o=g.o
  if g.u then g.u.Scale=sc end
  if g.pos then
   local cur=o.Position;local base=if same(cur,g.last) then cur-g.off else cur
   local off=UDim2.fromOffset(x,y);if g.u then off+=shiftOf(o.Size,g.ap,g.pv) end
   local p=base+off;o.Position=p;g.last=p;g.off=off
  end
  if tr.r then o.Rotation=o.Rotation-g.rot+r;g.rot=r end
 end
 s.a,s.s,s.x,s.y,s.r=a,sc,x,y,r
end
local function restore(s)
 fade(s.alpha,1)
 for _,g in ipairs(s.targets) do
  local o=g.o
  if g.pos then local cur=o.Position;o.Position=if same(cur,g.last) then cur-g.off else cur end
  if g.rot~=0 then o.Rotation=o.Rotation-g.rot end
  if g.u then dropScale(g.u);o.AnchorPoint=g.ap end
 end
end
local function identity(s) return (s.a==nil or s.a==1) and (s.s==nil or s.s==1) and s.x==0 and s.y==0 and s.r==0 end
-- how: 'end' (keeps an out end state for the owner to destroy; identity / restore / hide hand the built state back),
-- 'cancel' (built state now), 'gone' (destroyed: nothing to restore).
local function stopShot(o,how)
 local s=shots[o];if not s then return end;shots[o]=nil
 if s.hush then markDirty() end
 if how=='gone' then for _,g in ipairs(s.targets) do if g.u then dropScale(g.u) end end;return end
 if how=='end' and s.hide then o.Visible=false end
 if how=='cancel' or s.restore or identity(s) then restore(s) end
 if how=='cancel' and s.cancel then s.cancel() end -- a piece whose snapshot base is not its built state (reveal halos)
 if how=='end' and s.done then task.defer(s.done) end
end
local function tick()
 local now=os.clock();local ended
 for o,s in pairs(shots) do
  if o.Parent==nil then ended=ended or {};table.insert(ended,{o,'gone'})
  else
   local t=(now-s.t0)*s.sp-s.delay
   if t>=s.endT then apply(s,s.endT);ended=ended or {};table.insert(ended,{o,'end'}) else apply(s,math.max(0,t)) end
  end
 end
 if ended then for _,v in ipairs(ended) do stopShot(v[1],v[2]) end end
 if next(shots)==nil and beat then beat:Disconnect();beat=nil end
end
local function target(s,o,pos)
 local g={o=o,off=ZERO,rot=0,last=o.Position,pos=pos and (s.tr.x~=nil or s.tr.y~=nil or s.tr.s~=nil)}
 if s.tr.s then g.ap=o.AnchorPoint;g.pv=s.pivot;g.u=scaler(o);o.AnchorPoint=s.pivot end -- a follower shares the pivot
 if s.tr.a then snap(o,s.alpha,true) end
 table.insert(s.targets,g)
end
-- Motion.play(piece, token name | shot table, {hold, delay, restore, hide, done, cancel}). hold = MotionHold: the in part only.
-- done runs after a natural end (deferred), or at once when reduced motion skips the shot; cancel runs after a cancel's restore.
function M.stop(o) stopShot(o,'cancel') end
function M.playing(o) return shots[o]~=nil end
function M.play(o,name,opts)
 opts=opts or {}
 local tk=if type(name)=='table' then name else M.tokens[name]
 if not (tk and tk.keys and o and o.Parent) then return end
 M.stop(o)
 if M.reduced() then if opts.done then opts.done() end;return end
 local tr
 if type(tk.keys)=='function' then tr=tracks(tk.keys(o),tk.ease) else tr=tk._tr;if not tr then tr=tracks(tk.keys,tk.ease);tk._tr=tr end end
 local s={tr=tr,t0=os.clock(),sp=speed(),delay=opts.delay or tk.delay or 0,endT=if opts.hold then tk.inEnd or tk.dur else tk.dur,alpha={},targets={},restore=opts.restore,hide=opts.hide,done=opts.done,cancel=opts.cancel,hush=tk.hush,id=tk.id,pivot=tk.pivot or MID}
 target(s,o,true)
 local f=tk.follow and tk.follow(o);if f then target(s,f[1],f[2]) end
 shots[o]=s;apply(s,0)
 if not beat then beat=Run.RenderStepped:Connect(tick) end
end
-- Motion.show(piece, on, token, {instant}): Visible with the token's show/hide shots; acts only when `on` changes.
local shown=setmetatable({},weak)
function M.show(o,on,name,opts)
 on=on==true;local instant=opts and opts.instant
 if shown[o]==on and not (instant and shots[o]) then return end -- instant also cuts a show/hide in progress
 local first=shown[o]==nil;shown[o]=on
 if first and o.Visible==on then return end
 local tk=name and M.tokens[name];instant=instant or M.reduced() or not tk
 if on then M.stop(o);o.Visible=true;if not instant and tk.show then M.play(o,tk.show) end
 elseif not instant and tk.hide and o.Visible then M.play(o,tk.hide,{restore=true,hide=true})
 else M.stop(o);o.Visible=false end
end
-- Motion.to(instance, props, token, {out, instant, done}): a property tween, only when the target changes (Hud.render runs
-- often). out = the token's `out` duration. Reduced: a .15 s linear fade if the token is a group-transparency state change, else
-- instant. done runs when the props land (tween completed or set at once), not when a newer target replaces the tween.
local tos=setmetatable({},weak)
function M.to(o,props,name,opts)
 opts=opts or {};local tk=M.tokens[name] or {}
 local st=tos[o];if not st then st={goal={}};tos[o]=st end
 local diff=false
 for k,v in pairs(props) do local g=st.goal[k];if g==nil then g=o[k] end;if g~=v then diff=true end end
 for k,v in pairs(props) do st.goal[k]=v end
 if not diff then return end
 if st.tw then st.tw:Cancel();st.tw=nil end
 local d,ease,delay=if opts.out and tk.out then tk.out else tk.dur or 0,tk.ease,tk.delay
 if M.reduced() then d=if tk.reducedFade then .15 else 0;ease='linear';delay=0 end
 if opts.instant or d<=0 then for k,v in pairs(props) do o[k]=v end;if opts.done then opts.done() end;return end
 local done=opts.done
 st.tw=mk(o,info(d,ease,0,false,delay),props,if done then function(state) if state==Enum.PlaybackState.Completed then done() end end else nil);play(st.tw)
end
-- A Motion.to tween is running on o (Screens: tab sync waits; W.toggle: one knob slide at a time).
function M.busy(o) local st=tos[o];local tw=st and st.tw;return tw~=nil and (tw.PlaybackState==Enum.PlaybackState.Playing or tw.PlaybackState==Enum.PlaybackState.Delayed) end
-- Stop o's Motion.to tween where it is and forget its target (a touch / wheel / selection took over the scroll).
function M.cancel(o) local st=tos[o];if st then if st.tw then st.tw:Cancel() end;tos[o]=nil end end
-- Scroll tween (tab.scroll, §19): retargets a running glide when the landing moves; done when it lands (or is already there).
function M.scrollTo(sf,y,name,done)
 local p=Vector2.new(0,y)
 if M.busy(sf) and tos[sf].goal.CanvasPosition==p then return end
 M.cancel(sf)
 if sf.CanvasPosition==p then if done then done() end;return end
 M.to(sf,{CanvasPosition=p},name,{done=done})
end
-- Motion.value(key, to, token, fn, {from, instant}): a number tweened through fn (rings, the XP fill). The first call sets it;
-- later calls tween from the shown value when `to` changes; `from` restarts from that value.
local vals=setmetatable({},weak)
function M.value(key,to,name,fn,opts)
 opts=opts or {};local st=vals[key];if not st then st={};vals[key]=st end
 if opts.from==nil and st.goal==to then return end
 local first=st.goal==nil;st.goal=to;st.fn=fn
 if st.tw then st.tw:Cancel();st.tw=nil end
 local tk=M.tokens[name] or {}
 if (first and opts.from==nil) or opts.instant or M.reduced() or not tk.dur then st.cur=to;fn(to);return end
 if not st.nv then st.nv=Instance.new('NumberValue');st.nv.Changed:Connect(function(v) st.cur=v;st.fn(v) end) end
 local v0=if opts.from~=nil then opts.from else (st.cur or to);st.nv.Value=v0;st.cur=v0;fn(v0)
 st.tw=mk(st.nv,info(tk.dur,tk.ease,0,false,tk.delay),{Value=to});play(st.tw)
end

-- Loop engine. Entries register on attach (or Motion.loop); one entry per piece however many Tweens it needs.
local loops={} -- GuiObject -> entry
local reveals={} -- HudPiece='reveal' frames: loops outside them pause (cover rule)
local rootRef
local dirty=false
local evaluate
markDirty=function() if not dirty then dirty=true;Run.Heartbeat:Once(function() dirty=false;evaluate() end) end end -- at most once per frame
local watched={} -- ancestor -> {n, conns}: Visible / CanvasPosition / Enabled re-check the loops
local function watch(p)
 local w=watched[p];if w then w.n+=1;return end
 local c={}
 if p:IsA('GuiObject') then table.insert(c,p:GetPropertyChangedSignal('Visible'):Connect(markDirty)) end
 if p:IsA('ScrollingFrame') then table.insert(c,p:GetPropertyChangedSignal('CanvasPosition'):Connect(markDirty)) end
 if p:IsA('LayerCollector') then table.insert(c,p:GetPropertyChangedSignal('Enabled'):Connect(markDirty)) end
 watched[p]={n=1,c=c}
end
local function unwatch(p) local w=watched[p];if not w then return end;w.n-=1;if w.n<=0 then for _,x in ipairs(w.c) do x:Disconnect() end;watched[p]=nil end end
local function chain(e)
 for _,p in ipairs(e.chain or {}) do unwatch(p) end;e.chain={}
 local p=e.o
 while p and p~=game do
  if p:IsA('GuiObject') or p:IsA('LayerCollector') then watch(p);table.insert(e.chain,p) end
  if p:IsA('LayerCollector') then break end
  p=p.Parent
 end
end
local function inReveal(o) for r in pairs(reveals) do if o==r or o:IsDescendantOf(r) then return true end end;return false end
-- Shown = own Visible chain + an enabled LayerCollector, inside the nearest ScrollingFrame's window, not under a reveal. The box
-- tested (and sorted by Y) is the nearest clipping ancestor below the scroll when there is one: a buy shine rests outside its
-- button (x -40 %), a holo cycle is 4.8× wide, so their own rects say nothing about what is on screen.
local function visibleNow(e)
 local o=e.o;if next(reveals)~=nil and not inReveal(o) then return false end
 local sf,clip;local p=o;local ok=false
 while p and p~=game do
  if p:IsA('LayerCollector') then ok=p.Enabled;break end
  if p:IsA('GuiObject') then
   if not p.Visible then return false end
   local s=shots[p];if s and s.hush then return false end
   if p~=o and not sf then if p:IsA('ScrollingFrame') then sf=p elseif not clip and (p.ClipsDescendants or p:IsA('CanvasGroup')) then clip=p end end
  end
  p=p.Parent
 end
 if not ok then return false end
 local box=clip or o;e.box=box
 if sf then
  local a,b,c,d=box.AbsolutePosition,box.AbsoluteSize,sf.AbsolutePosition,sf.AbsoluteSize
  if a.X+b.X<=c.X or a.X>=c.X+d.X or a.Y+b.Y<=c.Y or a.Y>=c.Y+d.Y then return false end
 end
 return true
end
local function goals(e,to) -- channel goals → {instance = props}
 local o,b=e.o,e.base;local g={}
 local function put(i,k,v) local t=g[i];if not t then t={};g[i]=t end;t[k]=v end
 if to.x or to.y or to.xs then local p=b.pos;put(o,'Position',UDim2.new(if to.xs~=nil then to.xs else p.X.Scale,p.X.Offset+(to.x or 0),p.Y.Scale,p.Y.Offset+(to.y or 0))+e.shift) end
 if to.r then put(o,'Rotation',b.rot+to.r) end
 if to.s and e.u then put(e.u,'Scale',to.s) end
 if to.a then for _,v in ipairs(e.alpha) do put(v[1],v[2],1-(1-v[3])*to.a) end end
 return g
end
local function setNow(e,to) for i,props in pairs(goals(e,to)) do for k,v in pairs(props) do i[k]=v end end end
local function run(e,i)
 if not e.on then return end
 local st=e.steps[i];local nx=i%#e.steps+1
 if st.wait then e.thread=task.delay(st.wait/e.sp,function() e.thread=nil;run(e,nx) end)
 elseif st.set then setNow(e,st.set);run(e,nx)
 else for _,tw in ipairs(e.tw[i]) do play(tw) end end
end
local function startLoop(e)
 local o,tk=e.o,e.tk
 e.on=true;e.sp=speed();e.base={pos=o.Position,rot=o.Rotation,ap=o.AnchorPoint};e.shift=ZERO;e.alpha={};e.tw={}
 local u={};for _,st in ipairs(e.steps) do for k in pairs(st.to or st.set or {}) do u[k]=true end end;for k in pairs(tk.from or {}) do u[k]=true end;e.uses=u
 if u.s then e.u=scaler(o);if o.AnchorPoint~=MID then e.shift=shiftOf(o.Size,o.AnchorPoint);o.AnchorPoint=MID;o.Position=e.base.pos+e.shift end end
 if u.a then snap(o,e.alpha) end
 local n=#e.steps
 for i,st in ipairs(e.steps) do
  if st.to then
   local list={};e.tw[i]=list;local ti=info(st.dur,st.ease,if st.forever then -1 else 0,st.rev)
   for inst,props in pairs(goals(e,st.to)) do
    local adv=if #list==0 and not st.forever then function(state) if state==Enum.PlaybackState.Completed and e.on then run(e,i%n+1) end end else nil
    table.insert(list,mk(inst,ti,props,adv))
   end
  end
 end
 local d=(o:GetAttribute('MotionDelay') or 0)+(if tk.stagger and e.rank then tk.stagger[e.rank] or 0 else 0)
 local function go() e.thread=nil;if tk.from then setNow(e,tk.from) end;run(e,1) end
 if d>0 then e.thread=task.delay(d/e.sp,go) else go() end
end
local function stopLoop(e)
 e.on=false
 if e.thread then task.cancel(e.thread);e.thread=nil end
 for _,list in pairs(e.tw or {}) do for _,tw in ipairs(list) do tw:Cancel() end end;e.tw=nil
 local o,u=e.o,e.uses or {}
 if o.Parent then
  if u.x or u.y or u.xs or u.s then o.Position=e.base.pos end
  if u.r then o.Rotation=e.base.rot end
  if u.s then o.AnchorPoint=e.base.ap end
  fade(e.alpha,1)
 end
 if e.u then dropScale(e.u);e.u=nil end
end
local unregister
local function register(o,name)
 local tk=M.tokens[name];if loops[o] or not tk or tk.kind~='loop' then return end
 local e={o=o,name=name,tk=tk,cat=tk.cat or 'idle',steps=tk.steps or {{dur=tk.dur,ease=tk.ease,to=tk.to,rev=tk.rev,forever=true}},group=if tk.group=='parent' then o.Parent else o}
 loops[o]=e;chain(e)
 e.anc=o.AncestryChanged:Connect(function() if o:IsDescendantOf(game) then chain(e);markDirty() else unregister(o) end end)
 markDirty()
end
unregister=function(o)
 local e=loops[o];if not e then return end;loops[o]=nil
 e.anc:Disconnect();if e.on then stopLoop(e) end;for _,p in ipairs(e.chain) do unwatch(p) end;markDirty()
end
M.loop=register;M.unloop=function(o) unregister(o) end
-- A layout moved a playing loop's piece (Hud:apply → edge arrow): restart from the new base. Position-only loops.
function M.rebase(o) local e=loops[o];if not (e and e.on) then return end;local p=o.Position;stopLoop(e);o.Position=p;startLoop(e) end
evaluate=function()
 local red=M.reduced();local by={}
 for _,e in pairs(loops) do
  e.want=false;e.rank=nil
  if not red and visibleNow(e) then local l=by[e.cat];if not l then l={};by[e.cat]=l end;table.insert(l,e) end
 end
 for cat,l in pairs(by) do
  local cap=CAPS[cat]
  if cat=='rays' or cap then
   -- Budget: chosen top-down by screen Y (rays: the first of each token; idle: trail streak + swing count once).
   for _,e in ipairs(l) do local p=(e.box or e.o).AbsolutePosition;e.sy,e.sx=p.Y,p.X end
   table.sort(l,function(a,b) if a.sy~=b.sy then return a.sy<b.sy end;return a.sx<b.sx end)
   local rank,n={},0
   for _,e in ipairs(l) do
    local g=if cat=='rays' then e.name else e.group
    if rank[g]==nil then
     if cat=='rays' then rank[g]=1;e.want=true elseif n<cap then n+=1;rank[g]=n;e.want=true else rank[g]=false end
    else e.want=cat~='rays' and rank[g]~=false end
    if e.want then e.rank=rank[g] end
   end
  else for _,e in ipairs(l) do e.want=true end end
 end
 for _,e in pairs(loops) do if e.want and not e.on then startLoop(e) elseif not e.want and e.on then stopLoop(e) end end
end

-- LOW (effectsTier 0) hides every rays.* piece and gives back only the ones it hid, unless their owner hid them meanwhile:
-- owners that toggle a rays piece call Motion.visible (Shop hero mini), so the wanted state survives LOW.
local raysPieces=setmetatable({},weak);local lowHidden=setmetatable({},weak);local wanted=setmetatable({},weak);local lowOn=false
local function lowHide(o) if o.Visible then lowHidden[o]=true;o.Visible=false end end
local function trackRays(o)
 if raysPieces[o] then return end;raysPieces[o]=true
 o:GetPropertyChangedSignal('Visible'):Connect(function() if lowOn and o.Visible then lowHide(o) end end)
 if lowOn then lowHide(o) end
end
local function applyLow(on)
 if on==lowOn then return end;lowOn=on
 for o in pairs(raysPieces) do if on then lowHide(o) elseif lowHidden[o] then lowHidden[o]=nil;if o.Parent and wanted[o]~=false then o.Visible=true end end end
end
-- An owner's Visible for a piece Motion may hide (rays.* under LOW).
function M.visible(o,on)
 on=on==true;wanted[o]=on
 if lowOn and raysPieces[o] then if on then lowHidden[o]=true end;o.Visible=false else o.Visible=on end
end
-- Live gates: Controller calls refresh after T.configure; the player attributes call it too. Turning reduced on ends every
-- one-shot in its built state; the loops stop on the next evaluation.
local wasReduced=false
function M.refresh()
 local red=M.reduced()
 if red and not wasReduced then local l={};for o in pairs(shots) do table.insert(l,o) end;for _,o in ipairs(l) do M.stop(o) end end
 wasReduced=red;applyLow(M.noRays());markDirty()
end

-- Hatch reveal timeline (Task C), started by the scan when a HudPiece='reveal' frame appears (Feedback built its landed + named +
-- cta end state). Every tagged piece gets its shot now with delay = the token's `at` (+ MotionDelay), so it rests in its t = 0 key
-- (pre-spin / pre-landed pose) until its time; the title switch and the Collect hand-over are timers on the same QA-scaled clock.
-- The hub's loops pause underneath (cover rule, visibleNow). Reduced / LOW: nothing here, the built end state stays.
function M.revealTimeline(o)
 if M.reduced() then return end
 local mark=M.tokens['reveal.landed']
 for _,p in ipairs(o:GetDescendants()) do
  local name=p:IsA('GuiObject') and p:GetAttribute('Motion');local tk=type(name)=='string' and M.tokens[name]
  if tk then
   local delay=(tk.at or 0)+(p:GetAttribute('MotionDelay') or 0)
   if tk.kind=='loop' then M.later(function() if p.Parent then register(p,name) end end) -- rays.reveal, sparkle: from the next frame
   elseif name=='reveal.landed' then
    -- Spin title by tier (§19): "SOMETHING (RARE) IS COMING..." at revealTitle (30) px, its glow fitted to it; the built landed text
    -- and size come back at 3.5 s (L738, instant).
    local r=o:GetAttribute('RevealRarity');local text=if r=='Common' or r=='Uncommon' then mark.spinTitle.common else mark.spinTitle.rare
    local n=T.size(mark.spinSize);local tb=T.glowRevealTitle.b;local lbl=p:FindFirstChild('Text');local saved={}
    for _,x in ipairs(p:GetChildren()) do
     if x:IsA('TextLabel') then saved[x]={x.Text,x.TextSize};x.Text=text;x.TextSize=n
     elseif x:IsA('ImageLabel') and x.Name=='Glow' and lbl then saved[x]=x.Size;x.Size=UDim2.fromOffset(math.ceil(TextService:GetTextSize(text,n,lbl.Font,Vector2.new(1e4,1e4)).X)+2*tb,n+2*tb) end
    end
    M.after(mark.at,function() for x,v in pairs(saved) do if x.Parent then if typeof(v)=='UDim2' then x.Size=v else x.Text=v[1];x.TextSize=v[2] end end end end)
   elseif name=='reveal.halo' then
    -- Built fully transparent: the burst runs on the board's opaque ring (border solid, T 0) and glowHalo.t; a cancel hides them again.
    local built={}
    for _,x in ipairs(p:GetDescendants()) do
     if x:IsA('UIStroke') then built[x]='Transparency';x.Transparency=0 elseif x:IsA('ImageLabel') and x.Name=='Glow' then built[x]='ImageTransparency';x.ImageTransparency=T.glowHalo.t end
    end
    M.play(p,tk,{delay=delay,cancel=function() for x,k in pairs(built) do x[k]=1 end end})
   elseif name=='reveal.cta' then
    -- Not tappable or focusable before it shows; MotionShown hands it to Feedback's gamepad trap.
    p.Interactable=false;M.play(p,tk,{delay=delay})
    M.after(delay,function() if p.Parent then p.Interactable=true;p:SetAttribute('MotionShown',true) end end)
   elseif tk.kind=='shot' and tk.keys then M.play(p,tk,{delay=delay}) end
  end
 end
end

-- Attach (Controller, once, on SafeRoot): new GuiObjects are scanned after their builder finishes (attributes and layout are
-- set right after parenting), batched in one deferred pass.
local pending,flushing={},false
local laterLoops,loopsQueued={},false
local attachConns={}
local function scan(o)
 if not o.Parent or not o:IsA('GuiObject') then return end
 if o:GetAttribute('HudPiece')=='reveal' and not reveals[o] then
  reveals[o]=true;local c;c=o.AncestryChanged:Connect(function() if not (rootRef and o:IsDescendantOf(rootRef)) then reveals[o]=nil;c:Disconnect();markDirty() end end)
  markDirty();if M.revealTimeline then M.revealTimeline(o) end -- Task C
 end
 local name=o:GetAttribute('Motion');if type(name)~='string' then return end
 if string.sub(name,1,5)=='rays.' then trackRays(o) end
 if next(reveals)~=nil and not reveals[o] and inReveal(o) then return end -- the reveal timeline owns its pieces (Task C)
 if AUTO_SHOT[name] then
  local hold=o:GetAttribute('MotionHold')==true
  -- 'moment' variants by piece (P7 §22): the sanctuary Collect never grows; the reward modal (no HudPiece) keeps the centre pop.
  local piece=o:GetAttribute('HudPiece')
  M.play(o,if name=='moment' and piece=='collect' then 'moment.collect' elseif name=='moment' and piece==nil then 'moment.modal' else name,{hold=hold})
  if name=='carry.pop' and not hold then local cp=portraitOf(o);if cp then M.play(cp,'carry.portraitIn') end end
 elseif M.tokens[name] and M.tokens[name].kind=='loop' then
  -- Loops register a frame later (ancestry watchers, visibility, tweens stay off the build frame); one-shots start now so their
  -- t = 0 pose is what renders first.
  table.insert(laterLoops,{o,name});if not loopsQueued then loopsQueued=true;M.later(function() loopsQueued=false;local l=laterLoops;laterLoops={};for _,v in ipairs(l) do if v[1].Parent then register(v[1],v[2]) end end end) end
 end
end
-- One deferred flush per batch: DescendantAdded only appends (no defer, no attribute read per instance).
local function flush() flushing=false;local list=pending;pending={};for _,o in ipairs(list) do scan(o) end end
local function queue(o) table.insert(pending,o);if not flushing then flushing=true;task.defer(flush) end end
function M.detach()
 for _,c in ipairs(attachConns) do c:Disconnect() end;table.clear(attachConns)
 for o in pairs(loops) do unregister(o) end;rootRef=nil
end
function M.attach(root)
 M.detach();rootRef=root
 table.insert(attachConns,root.DescendantAdded:Connect(queue))
 for _,o in ipairs(root:GetDescendants()) do queue(o) end
 local me=Players.LocalPlayer
 if me then for _,a in ipairs({'MountainReducedMotion','MountainSimplifiedVFX'}) do table.insert(attachConns,me:GetAttributeChangedSignal(a):Connect(M.refresh)) end end
 M.refresh()
end
-- Budget check (UIProbe motionStats): loop entries playing (one per budget group: a skin's trail streak + swing = one entry, as the
-- idle cap counts them), raw Tweens playing, entries per category, one-shots playing.
function M.stats()
 local n,by,tw,sh,seen,names=0,{},0,0,{},{}
 for _,e in pairs(loops) do if e.on and not seen[e.group] then seen[e.group]=true;n+=1;by[e.cat]=(by[e.cat] or 0)+1 end end
 for _ in pairs(live) do tw+=1 end
 for o,s in pairs(shots) do sh+=1;table.insert(names,o.Name..':'..tostring(s.id)) end -- QA: which one-shots are playing
 return {loops=n,tweens=tw,byCat=by,oneShots=sh,shotNames=names,reduced=M.reduced(),timeScale=speed()}
end
return M
