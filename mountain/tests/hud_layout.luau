-- Glassbloom HUD geometry (P4): climb&collect/design/hud-glassbloom-intel.md §2 HUD builders + §3 containment, plan §5/§15.
-- 6 sizes x touch on/off x topbar off/in-row/above-root x large text x HUD scale S/M/L, every HUD state.
local P=require('../shared/UIPresentation')
assert(type(P.hudLayout)=='function','Glassbloom geometry is missing')
local n=0;local function check(v,name) assert(v,name);n+=1 end
local TOL=.75 -- §3 tolerance on every inside/overlap test
local function R(r,s) return {x=r.x*s,y=r.y*s,w=r.w*s,h=r.h*s} end -- virtual -> real
local function overlap(a,b) return a.x<b.x+b.w-TOL and b.x<a.x+a.w-TOL and a.y<b.y+b.h-TOL and b.y<a.y+a.h-TOL end
local function inside(a,b) return a.x>=b.x-TOL and a.y>=b.y-TOL and a.x+a.w<=b.x+b.w+TOL and a.y+a.h<=b.y+b.h+TOL end
local function near(a,b) return math.abs(a-b)<.01 end
-- Hit areas (STOP 1 G1): centred max(44, drawn) per axis, trimmed at the midpoint between overlapping neighbours; must stay >= 44.
local function hit(r) local w,h=math.max(44,r.w),math.max(44,r.h);return {x=r.x+r.w/2-w/2,y=r.y+r.h/2-h/2,w=w,h=h} end
local function hitsOk(list,where,floor)
 local hits={};for i,r in ipairs(list) do hits[i]=hit(r) end
 for i=1,#list do for j=i+1,#list do
  local a,b,ha,hb=list[i],list[j],hits[i],hits[j]
  if overlap(ha,hb) then
   if a.x+a.w<=b.x or b.x+b.w<=a.x then
    local l,r=if a.x<b.x then ha else hb,if a.x<b.x then hb else ha;local m=((if a.x<b.x then a.x+a.w else b.x+b.w)+(if a.x<b.x then b.x else a.x))/2
    l.w=m-l.x;r.w=r.x+r.w-m;r.x=m
   else
    local t,u=if a.y<b.y then ha else hb,if a.y<b.y then hb else ha;local m=((if a.y<b.y then a.y+a.h else b.y+b.h)+(if a.y<b.y then b.y else a.y))/2
    t.h=m-t.y;u.h=u.y+u.h-m;u.y=m
   end
  end
 end end
 for i,h in ipairs(hits) do check(h.w>=floor-TOL and h.h>=floor-TOL,where..' hit area '..i..' under '..floor..' after trimming') end
end
-- Coverage (§3): union of permanent boxes on a 2 px grid (floor start, ceil end) + the native jump rect (replaces the board's
-- 70 px jump orb, D5), as % of the screen. Hit areas excluded.
local function coverage(boxes,w,h)
 local cells={};local count=0
 for _,b in ipairs(boxes) do
  for gx=math.floor(math.max(0,b.x)/2),math.ceil(math.min(w,b.x+b.w)/2)-1 do for gy=math.floor(math.max(0,b.y)/2),math.ceil(math.min(h,b.y+b.h)/2)-1 do
   local k=gx*100000+gy;if not cells[k] then cells[k]=true;count+=1 end
  end end
 end
 return 100*count*4/(w*h)
end
local SIZES={{749,330},{844,390},{932,430},{1024,700},{1180,780},{1600,860}}
local covered={};local stacked=0
for _,v in ipairs(SIZES) do
 local w,h=v[1],v[2]
 for _,touch in ipairs({false,true}) do for _,bar in ipairs({'off','row','above'}) do for _,large in ipairs({false,true}) do for _,pref in ipairs({0,.5,1}) do
  local where=w..'x'..h..(if touch then ' touch' else '')..' '..bar..(if large then ' large' else '')..' s'..pref
  -- Roblox TouchGui (PlayerModule): small screen = min(w,h) <= 500 -> jump 70 at (1,-95, 1,-90), else 120 at (1,-170, 1,-210);
  -- the dynamic thumbstick is a gesture region, left 40 % x bottom 2/3.
  local smallScreen=math.min(w,h)<=500
  local jump=if smallScreen then {x=w-95,y=h-90,w=70,h=70,kind='jump'} else {x=w-170,y=h-210,w=120,h=120,kind='jump'}
  local dynamic={x=0,y=h/3,w=.4*w,h=h*2/3,kind='dynamic'}
  local obstacles=if touch then {jump,dynamic} else {}
  -- 'row': the topbar row overlaps the root top; 'above': the root starts below it (HUD v2 measured, y -58).
  local topbar=if bar=='row' then {x=116,y=0,w=w-116,h=58} elseif bar=='above' then {x=164,y=-58,w=w-164,h=58} else nil
  local screen=if bar=='above' then {x=0,y=-58,w=w,h=h+58} else {x=0,y=0,w=w,h=h}
  local s=P.hudScale(pref,w)
  local l=P.hudLayout(w,h,obstacles,touch,topbar,{scale=s,screen=screen,coinW=if large then 120 else 103,edgeW=if large then 112 else 100,abilityW=if large then 96 else 84})
  local Z={S=R(l.zones.S,s),C=R(l.zones.C,s),T=R(l.zones.T,s),M=R(l.zones.M,s)}
  local root={x=0,y=0,w=w,h=h}
  check(l.scale==s and s<=P.hudScales[pref]+1e-9 and s>=P.hudScales[0]-1e-9,where..' scale')
  check(l.topbar==(bar~='off'),where..' topbar row used whenever it is available')
  if l.topbar then check(near(l.gear.y*s,topbar.y+math.min(12,topbar.h-44*s)) and near((l.gear.x+44)*s,w-12*s),where..' gear flush right, level with the core buttons') end
  -- Rail (G9): fits, nodes inside, spaced, sized 12/15 or 10/13 under 110.
  check(l.railFits,where..' rail nodes fit')
  check(l.railNode==(if l.rail.h<110 then 10 else 12) and l.railSummit==l.railNode+3,where..' rail node size')
  for k=1,7 do
   local nd=l.railNodes[k];check(inside(nd,{x=0,y=0,w=l.rail.w,h=l.rail.h}),where..' node '..k..' inside rail')
   if k<7 then check(l.railNodes[k+1].y+l.railNodes[k+1].h<=nd.y+TOL,where..' node '..k..' below node '..(k+1)) end
  end
  local perm={
   tr=l.tr,rail=l.rail,dock=l.dock,dockChase=l.dockChase,bat=l.bat,pickup=l.pickup,sprint=l.sprint,portrait=l.portrait,edge=l.edge,
   team=l.team,dodge=l.dodge,ability=l.ability,
  }
  -- Visible permanent pieces per state (intel §2 HUD states; G6 battle; pick-up = revealed phase, so rest only).
  local states={
   rest={'tr','rail','dock','bat','pickup'},carry={'tr','rail','dock','bat','portrait','edge'},
   chase={'tr','rail','dockChase','bat','portrait','edge'},sanctuary={'tr','dock'},battle={'tr','rail','team','dodge','ability','portrait'},
  }
  local centred={dock=true,dockChase=true,team=true,ability=true} -- owner 2026-10-27: the centred row may sit over the gesture region
  for state,keys in pairs(states) do
   if touch then table.insert(keys,'sprint') end
   for i,a in ipairs(keys) do
    local r=R(perm[a],s)
    check(inside(r,Z.S),where..' '..state..' '..a..' outside S')
    if a=='tr' and l.topbar then check(inside(r,{x=topbar.x,y=topbar.y,w=topbar.w,h=topbar.h}),where..' tr outside the topbar row')
    else check(inside(r,root),where..' '..state..' '..a..' outside the safe root') end
    for _,z in ipairs({'C','T','M'}) do check(not overlap(r,Z[z]),where..' '..state..' '..a..' overlaps '..z) end
    for j=i+1,#keys do check(not overlap(r,R(perm[keys[j]],s)),where..' '..state..' '..a..' overlaps '..keys[j]) end
    if touch then
     check(not overlap(r,jump),where..' '..state..' '..a..' overlaps the native jump')
     if not centred[a] and a~='rail' and a~='portrait' and a~='edge' then check(not overlap(hit(r),dynamic),where..' '..state..' '..a..' hit area over the thumbstick region') end
    end
   end
  end
  -- Dock buttons and centred controls never overlap the native jump either.
  for i,b in ipairs(l.dockButtons) do check(inside(b,l.dock),where..' dock button '..i..' inside dock') end
  for i,b in ipairs(l.slots) do check(inside(b,l.team),where..' slot '..i..' inside team') end
  -- Hit areas per state (drawn sizes; G1).
  local function scaled(list) local o={};for i,r in ipairs(list) do o[i]=R(r,s) end;return o end
  -- G1 vs G2 conflict: at HUD scale S the 42 px dock buttons sit at a real pitch of 48 x .85 = 40.8 < 44, so neighbouring hit
  -- areas trim to the pitch. The floor is 44 at M/L and the dock pitch at S (flagged for the owner).
  local floor=44 -- owner 2026-10-28: the dock/launcher pitch stays 48 on screen at every HUD scale
  local db=l.dockButtons
  -- hud-polish E: launcher rects from the expanded card (x 14, y 69); the compact card's info toggle = its top 69 (border +
  -- padding + rows + padding), the expanded one the same 69 under the launcher (the launcher sits above it in Z).
  local card=l.card;local launch={};for i=1,5 do launch[i]={x=card.x+14+(i-1)*(42+l.dockGap),y=card.y+69,w=42,h=42} end
  local cc=l.cardCompact;local info={x=cc.x,y=cc.y,w=cc.w,h=69}
  hitsOk(scaled({l.coin,l.gear,db[1],db[2],db[3],db[4],db[5],l.bat,l.pickup,l.sprint}),where..' rest',floor)
  hitsOk(scaled({l.coin,l.gear,db[1],db[2],db[3],l.bat,l.sprint}),where..' chase',floor)
  hitsOk(scaled({l.coin,l.gear,db[1],db[2],db[3],db[4],db[5],l.sprint,launch[1],launch[2],launch[3],launch[4],launch[5]}),where..' sanctuary',floor)
  hitsOk(scaled({l.coin,l.gear,db[1],db[2],db[3],db[4],db[5],l.sprint,info}),where..' sanctuary compact card',floor)
  -- Expanded: the launcher hits (44 real px, centred on 42) overlap the info toggle by (44/s - 42)/2 from above in Z; the rest >= 44.
  check((69-math.max(0,(44/s-42)/2))*s>=44-TOL,where..' expanded card info toggle >= 44 under the launcher hits')
  -- Both cards: same bottom (H - 78), centred on the dock axis, at least 10 above the dock top, clear of the coin pill / gear.
  check(near(card.y+card.h,cc.y+cc.h) and near(card.y+card.h,h/s-78) and card.h==123 and cc.h==71 and card.w==cc.w,where..' compact 71 / expanded 123 share the bottom H - 78')
  for nm,r in pairs({card=card,cardCompact=cc}) do
   check(near(r.x+r.w/2,l.dock.x+l.dock.w/2),where..' '..nm..' on the dock axis')
   check(r.y+r.h<=l.dock.y-10+1e-6 and r.y+r.h<=l.dockChase.y-10+1e-6,where..' '..nm..' ends 10 above the dock top')
   check(not overlap(R(r,s),R(l.tr,s)),where..' '..nm..' clear of the coin pill / gear')
  end
  hitsOk(scaled({l.coin,l.gear,l.slots[1],l.slots[2],l.slots[3],l.dodge,l.ability,l.sprint}),where..' battle',floor)
  for i=1,5 do check(inside(launch[i],card),where..' launcher '..i..' inside the player card') end
  -- Transients (§3): inside S, clear of C. Owner 2026-10-28 (P7 E): every mountain transient is also clear of M, and the band
  -- ones (P.bandSlot) clear of the coin pill + gear. Text-fitted widths use their caps; the rail label a full 18-checkpoint label.
  -- The player card (D2 launcher, opened by the player) is exempt from M.
  local tw=l.toastMax
  local transients={
   toast={x=l.toast.x-tw,y=l.toast.y,w=tw,h=l.toast.h},xpLine=l.xpLine,card=l.card,cardCompact=l.cardCompact,
   railLabel={x=l.railLabel.x,y=l.railLabel.y,w=math.min(171,l.railLabelMax),h=l.railLabel.h},
  }
  -- Band transients at their natural board boxes (Feedback / Hud): banner h59, carry pop-up h78, boss bar h76, RUN! row
  -- (owner 2026-10-28, P7 F: word line 125 with the awake pill h27 6 right of it, centred on the line), moment block (line 77 + 8
  -- + sub 20, or the line alone). Widths: short / typical / the cap. RUN! row (P.bandRun) = word box (LuckiestGuy 104 "RUN!" 230 + 2 x 5; large
  -- text 106: 235 + 10, font advance widths) + 6 + pill (FredokaOne 13 "VEYLITH IS AWAKE" 124 / "FLORAVELLE IS AWAKE" 154 + 2 x
  -- 15.5; large 15: 143 / 177), and a cap-wide pill (shrinks by fp).
  local B=l.band;local glows={} -- drawn glow extents: checked against M only (they may run past the screen edge)
  check(near(B.top,l.gear.y) and near(B.low,l.toast.y) and near(B.cx,l.dock.x+l.dock.w/2),where..' band rows = coin-pill row / toast line, centred')
  local kinds={banner=59,carryPop=78,boss=76,moment=105,momentTitle=77}
  local GLOW={banner=18,carryPop=26,boss=18,moment=0,momentTitle=0} -- W.glow extents at rest: glass 18, rarity cpop 26
  check(B.margin==2,where..' 2 px safety margin above M')
  local RW=if large then 245 else 241
  local runP={if large then 174 else 155,if large then 208 else 185,l.bandMax}
  local seats={}
  for kind,hh in pairs(kinds) do for i,ww in ipairs({120,300,l.bandMax}) do
   local e=GLOW[kind];local r=P.bandSlot(l,ww,hh,nil,e);seats[kind..i]=r;transients['band '..kind..' w'..ww]=r
   check(r.f>0 and r.f<=1 and near(r.w,ww*r.f) and near(r.h,hh*r.f) and near(r.e,e*r.f),where..' '..kind..' one factor (box and glow)')
   check(r.y==B.top or r.y==B.low,where..' '..kind..' in a band row')
   -- Follow-up (live 874x401): the DRAWN bottom (box + glow) ends the 2 px margin above M's top, no tolerance.
   check(r.y+r.h+r.e<=B.keep-B.margin+1e-6,where..' '..kind..' w'..ww..' glow within 2 px of M')
   if r.f>=1 and ww<=B.topMax and B.top+hh+e<=B.keep-B.margin then check(r.y==B.top,where..' '..kind..' w'..ww..' fits the top row but sits low') end
   if r.top then check(not overlap(R(r,s),R(l.tr,s)) and r.x>=Z.C.x+Z.C.w-TOL,where..' '..kind..' top row clear of the coin pill / C') end
  end end
  -- RUN! shock ring at the word line; a moment stacked under a tier-2 message; the sanctuary Collect.
  for i=1,3 do
   -- RUN! row (P.bandRun): the word at its own band factor, the pill at fp (width only), 6 apart, the row centred.
   local pw=runP[i];local run,word,pill=P.bandRun(l,RW,pw,125,27);local f=run.f;seats['run'..i]=run
   local ws=P.bandSlot(l,RW,125);local max=if run.top then B.topMax else B.lowMax
   check(near(f,ws.f) and run.y==ws.y and near(word.w,RW*f) and near(word.h,125*f),where..' RUN! word keeps its own band factor')
   check(near(pill.f,math.max(.05,math.min(1,(max-RW*f-6)/pw))) and near(pill.w,pw*pill.f) and near(pill.h,27*pill.f),where..' RUN! pill factor = width room only')
   check(near(pill.x-(word.x+word.w),6) and near(pill.y+pill.h/2,word.y+word.h/2) and near(run.x+run.w/2,B.cx) and near(pill.x+pill.w,run.x+run.w),where..' RUN! pill 6 right of the word, on its line, row centred')
   check(run.w<=max+1e-6,where..' RUN! row fits its band row')
   transients['run row'..i]=run;transients['run word'..i]=word;transients['run pill'..i]=pill
   local wcx=word.x+word.w/2;local k=P.bandShock(l,word,125,wcx);transients['shock'..i]=k
   check(k.w<=180*f+1e-6 and near(k.x+k.w/2,wcx) and near(k.y+k.h/2,word.y+125*f/2),where..' shock ring centred on the word, <= 180 x f')
   for _,x in ipairs({word,pill,k}) do check(x.y+x.h<=B.keep-B.margin+1e-6,where..' RUN! word / pill / ring within 2 px of M') end
   if run.top then for _,x in ipairs({run,k}) do check(not overlap(R(x,s),R(l.tr,s)) and x.x>=Z.C.x+Z.C.w-TOL,where..' RUN! row / ring clear of the coin pill / C') end end
   for j,under in ipairs({seats['banner'..i],seats['carryPop'..i]}) do
    -- Feedback stacks only at or above the moment's floor (LG 64 / FO 13 sub); below it the moment waits for the band to clear.
    local mo=P.bandSlot(l,300,105,under)
    if mo.f>=P.bandFloorOf({{64,'display'},{13,'body'}}) then transients['stacked moment '..i..'.'..j]=mo;stacked+=1 end
    check(mo.y>=under.y+under.h+under.e+B.gap-TOL,where..' stacked moment below the tier-2 message and its glow')
   end
   local mo=seats['moment'..i];local c=P.bandCollect(l,mo);transients['collect'..i]=c
   check(c.w==190 and c.h==46,where..' Collect keeps 190x46 (touch target, never band-scaled)')
   check(not overlap(R(c,s),R(l.tr,s)) and not overlap(R(c,s),R(mo,s)),where..' Collect clear of the coin pill and its moment')
   if c.below then check(c.y>=mo.y+mo.h,where..' Collect below its moment') end
   glows['collect'..i]={x=c.x-18,y=c.y-18,w=c.w+36,h=c.h+36} -- W.cta glowCta 18
  end
  check(tw>=150 and l.bandMax>=200,where..' message caps leave room for text')
  glows.toast={x=l.toast.x-tw-18,y=l.toast.y-18,w=tw+36,h=l.toast.h+36} -- glass glow 18
  for name,t in pairs(transients) do
   local r=R(t,s)
   check(inside(r,Z.S),where..' transient '..name..' outside S')
   check(not overlap(r,Z.C),where..' transient '..name..' touches C')
   if name~='card' and name~='cardCompact' then check(not overlap(r,Z.M),where..' transient '..name..' enters M') end
  end
  for name,t in pairs(glows) do check(not overlap(R(t,s),Z.M),where..' '..name..' glow enters M') end
  -- Coverage gates (§3, P§4): 844x390, scale M, normal text, touch (sprint + native jump), permanent boxes only.
  if w==844 and touch and pref==.5 and not large and bar=='off' then
   local function cov(keys) local boxes={jump};for _,k in ipairs(keys) do table.insert(boxes,R(perm[k],s)) end;return coverage(boxes,w,h) end
   covered.rest=cov({'tr','rail','dock','bat','sprint'});covered.chase=cov({'tr','rail','dockChase','bat','sprint','portrait','edge'})
   check(covered.rest<=11.6,'rest coverage '..covered.rest..' > 11.6 %')
   check(covered.chase<=12,'chase coverage '..covered.chase..' > 12 %')
  end
 end end end end
end
-- Board conformance at 844x390, scale M, no topbar (intel §2 positions).
local b=P.hudLayout(844,390,{},false,nil,{scale=1})
local function is(r,x,y,w,h) return near(r.x,x) and near(r.y,y) and near(r.w,w) and near(r.h,h) end
check(is(b.dock,297,322,250,58) and is(b.dockChase,345,322,154,58),'board dock 250x58 / chase 154x58 at (.5,0, 1,-10)')
check(is(b.sprint,694,316,54,54) and is(b.bat,772,242,52,52) and is(b.pickup,772,180,52,52),'board orbs: sprint (1,-96,1,-20), bat (1,-20,1,-96), pick-up bottom -158')
check(is(b.portrait,556,318,52,62) and is(b.edge,736,.36*390,100,36),'board carry portrait (.5,134, 1,-10) and edge arrow (1,-8, .36,0)')
check(is(b.rail,14,70,22,390*.52-10-70) and b.railNode==12 and b.railSummit==15,'board rail (0,14, 0,70), bottom 48 % + 10')
check(is(b.xpLine,304,312,236,6) and is(b.gear,788,7,44,44) and b.toast.x==832 and b.toast.y==60,'board tr, XP line and toast slot')
-- P7 E band at 844x390: top row y 7 between C (116 + 8) and the coin pill (677 - 8), centred = 2 x min(422-124, 669-422) = 494;
-- low row y 60; boxes end at M's top 93.6.
check(b.band.top==7 and b.band.low==60 and near(b.band.topMax,494) and b.band.lowMax==612 and near(b.band.keep,93.6),'board band rows')
check(is(P.bandSlot(b,300,59),272,7,300,59),'board section banner: top row, full size')
do local r,wd,pl=P.bandRun(b,241,185,125,27);check(near(r.f,84.6/125) and r.y==7 and pl.f==1 and near(r.w,241*84.6/125+6+185),'board RUN! row: word top row scaled to end 2 px above M, pill full size') end
check(is(b.card,422-131,390-78-123,262,123) and is(b.cardCompact,422-131,390-78-71,262,71),'board player card: expanded 262x123 / compact 262x71, dock axis, bottom -78')
check(is(b.team,327,310,190,70) and is(b.ability,380,279,84,27) and b.dodge==b.bat,'G6 battle: specials dock, ability chip above, dodge in the bat slot')
local short=P.hudLayout(749,330,{},false,nil,{scale=1})
check(short.rail.h<110 and short.railNode==10 and short.railSummit==13 and short.railFits,'G9: short rail uses 10/13 nodes')
check(short.ability.x>=short.zones.M.x+short.zones.M.w,'ability chip slides right of M on short phones')
check(P.hudScale(0,844)==.85 and P.hudScale(.5,844)==1 and P.hudScale(1,844)==1.15 and P.hudScale(1,749)<1.15 and P.hudScale(1,749)>1,'G2 scales, L clamped to fit 749 px')
check(P.hudScale(nil,844)==1 and P.hudScale(.5,nil)==1,'scale defaults to M')
print(string.format('PASS %d Glassbloom layout checks (rest %.1f %%, chase %.1f %%, %d stacked moments)',n,covered.rest or -1,covered.chase or -1,stacked))
