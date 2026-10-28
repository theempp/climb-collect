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
local covered={}
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
  local floor=math.min(44,48*s)
  local db=l.dockButtons
  local card=l.card;local launch={};for i=1,5 do launch[i]={x=card.x+14+(i-1)*48,y=card.y+70,w=42,h=42} end
  hitsOk(scaled({l.coin,l.gear,db[1],db[2],db[3],db[4],db[5],l.bat,l.pickup,l.sprint}),where..' rest',floor)
  hitsOk(scaled({l.coin,l.gear,db[1],db[2],db[3],l.bat,l.sprint}),where..' chase',floor)
  hitsOk(scaled({l.coin,l.gear,db[1],db[2],db[3],db[4],db[5],l.sprint,launch[1],launch[2],launch[3],launch[4],launch[5]}),where..' sanctuary',floor)
  hitsOk(scaled({l.coin,l.gear,l.slots[1],l.slots[2],l.slots[3],l.dodge,l.ability,l.sprint}),where..' battle',floor)
  for i=1,5 do check(inside(launch[i],card),where..' launcher '..i..' inside the player card') end
  -- Transients (§3): inside S, clear of C. Text-fitted widths use their caps; the rail label uses a full 18-checkpoint label.
  local function centredBox(r,width) return {x=r.x-width/2,y=r.y,w=width,h=r.h} end
  local tw=l.toastMax
  local transients={
   toast={x=l.toast.x-tw,y=l.toast.y,w=tw,h=l.toast.h},banner=centredBox(l.banner,l.bandMax),carryPop=centredBox(l.carryPop,l.bandMax),
   boss=centredBox(l.boss,l.bandMax),awake=centredBox(l.awake,l.bandMax),momentSub=centredBox(l.momentSub,l.bandMax),
   run=l.run,moment=l.moment,collect=l.collect,xpLine=l.xpLine,card=l.card,railLabel={x=l.railLabel.x,y=l.railLabel.y,w=171,h=l.railLabel.h},
  }
  check(tw>=150 and l.bandMax>=200,where..' message caps leave room for text')
  for name,t in pairs(transients) do
   local r=R(t,s)
   check(inside(r,Z.S),where..' transient '..name..' outside S')
   check(not overlap(r,Z.C),where..' transient '..name..' touches C')
  end
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
check(is(b.xpLine,304,312,236,6) and is(b.gear,788,7,44,44) and b.toast.x==832 and b.toast.y==60 and b.banner.y==62 and b.carryPop.y==60,'board tr, XP line and message slots')
check(near(b.run.y,.19*390) and near(b.moment.y,.30*390) and is(b.card,297,390-78-124,262,124),'board RUN!, moment and player card')
check(is(b.team,327,310,190,70) and is(b.ability,380,279,84,27) and b.dodge==b.bat,'G6 battle: specials dock, ability chip above, dodge in the bat slot')
local short=P.hudLayout(749,330,{},false,nil,{scale=1})
check(short.rail.h<110 and short.railNode==10 and short.railSummit==13 and short.railFits,'G9: short rail uses 10/13 nodes')
check(short.ability.x>=short.zones.M.x+short.zones.M.w,'ability chip slides right of M on short phones')
check(P.hudScale(0,844)==.85 and P.hudScale(.5,844)==1 and P.hudScale(1,844)==1.15 and P.hudScale(1,749)<1.15 and P.hudScale(1,749)>1,'G2 scales, L clamped to fit 749 px')
check(P.hudScale(nil,844)==1 and P.hudScale(.5,nil)==1,'scale defaults to M')
print(string.format('PASS %d Glassbloom layout checks (rest %.1f %%, chase %.1f %%)',n,covered.rest or -1,covered.chase or -1))
