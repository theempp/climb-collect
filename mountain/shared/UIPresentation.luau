-- Pure view models. These helpers never award, equip, or mutate profile data.
local C = if script then require(script.Parent.Catalog) else require('./Catalog')
local R = if script then require(script.Parent.Rules) else require('./Rules')
local P = {}
local rarityOrder = {Common=1, Uncommon=2, Rare=3, Epic=4, Mythic=5, Legendary=6}
local roleSkills = {Damage='Burst', Support='Heal', Tank='Shield', Speed='Haste', Control='Control', Magic='Burn'}
local function finite(value)
 return type(value)=='number' and value==value and math.abs(value)<math.huge
end
function P.remaining(deadline, now)
 if not finite(deadline) or not finite(now) then return 0 end
 return math.max(0,math.ceil(deadline-now))
end
function P.formatTime(seconds)
 local n = if finite(seconds) then math.max(0,math.ceil(seconds)) else 0
 if n>=3600 then return string.format('%d:%02d:%02d',math.floor(n/3600),math.floor(n/60)%60,n%60) end
 return string.format('%d:%02d',math.floor(n/60),n%60)
end
function P.creature(c)
 local species = c and C.byId[c.species]
 if not species then
  return {name='Unknown creature',rarity='Unknown',element='Unknown',role='Unknown',stage=1,attack=0,health=0,xpRequired=0,abilityNames={}}
 end
 local level = if finite(c.level) then math.clamp(math.floor(c.level),1,50) else 1
 local stats = R.stats({species=c.species,level=level,specialization=c.specialization})
 return {name=species.name,rarity=species.rarity,element=species.element,role=species.role,
  stage=R.stage(level),attack=stats.attack,health=stats.health,xpRequired=if level>=50 then 0 else level*40,
  abilityNames=if species.abilities then table.clone(species.abilities) else {roleSkills[species.role] or 'Special'}}
end
function P.filterCreatures(profile,query,rarity,sort)
 local found = {}
 local search = string.lower(tostring(query or '')):match('^%s*(.-)%s*$') or ''
 local tier = string.lower(tostring(rarity or 'all'))
 local teamOrder = {}
 for slot,id in ipairs(if profile then profile.team or {} else {}) do teamOrder[id]=slot end
 for _,c in ipairs(if profile then profile.creatures or {} else {}) do
  local s = C.byId[c.species]
  if s then
   local searchable = string.lower(table.concat({s.name,s.rarity,s.element,s.role,c.id or ''},' '))
   if (tier=='' or tier=='all' or string.lower(s.rarity)==tier) and (search=='' or string.find(searchable,search,1,true)) then
    table.insert(found,c)
   end
  end
 end
 local mode=string.lower(tostring(sort or 'name'))
 table.sort(found,function(a,b)
  local sa,sb=C.byId[a.species],C.byId[b.species]
  if mode=='team' and (teamOrder[a.id] or 4)~=(teamOrder[b.id] or 4) then return (teamOrder[a.id] or 4)<(teamOrder[b.id] or 4) end
  if mode=='level' and a.level~=b.level then return a.level>b.level end
  if mode=='rarity' and rarityOrder[sa.rarity]~=rarityOrder[sb.rarity] then return rarityOrder[sa.rarity]>rarityOrder[sb.rarity] end
  if sa.name~=sb.name then return sa.name<sb.name end
  return tostring(a.id)<tostring(b.id)
 end)
 return found
end
function P.quest(profile)
 if not profile then return {title='Preparing your mountain',detail='Waiting for the server profile.',progress=0,total=1} end
 if profile.schema==2 then
  if profile.run then return {title=if profile.run.phase=='carried' then 'Escape to sanctuary' elseif profile.run.phase=='revealed' then 'Pick up your creature' else 'Break the guarded egg',detail='Follow the clear downhill lane. Only the sanctuary exit secures this attempt.',progress=0,total=1} end
  local count=0;for k=1,6 do if profile.discoveries[k..':entrance'] then count+=1 end end
  return {title='Explore any of the six sections',detail='Find a visible egg, tap each strike, then carry your creature to sanctuary.',progress=count,total=6}
 end
 local discoveries,wins=profile.discoveries or {},profile.wins or {}
 for k,kingdom in ipairs(C.kingdoms) do
  if not wins[tostring(k)] then
   if not discoveries[tostring(k)..':entrance'] then
    return {title='Explore '..kingdom.name,detail='Reach the entrance checkpoint on the mountain route.',progress=0,total=1}
   end
   return {title='Challenge '..C.guardians[k].name,detail='Find the Guardian altar in '..kingdom.name..'.',progress=k-1,total=#C.kingdoms}
  end
 end
 return {title=if discoveries.summit then 'Summit discovered' else 'Reach the Impossible Summit',
  detail=if discoveries.summit then 'Explore branches and return for Legendary Trials.' else 'Follow the Astral Crown route to the summit.',
  progress=if discoveries.summit then 1 else 0,total=1}
end
function P.capabilities()
 -- Connected describes a real service boundary, never player eligibility.
 return {
  inventory={status='connected',reason='Authoritative creature inventory and three active team slots.'},
  training={status='connected',reason='Train at the expedition refuge with server-validated coins and XP.'},
  evolution={status='connected',reason='Level stages at 15 and 35; permanent specialization at 25.'},
  eggs={status='connected',reason='Carried and secured eggs, three incubators, timed free hatching.'},
  income={status='connected',reason='Collect habitat production eggs and bank them for coins on your own plot.'},
  travel={status='connected',reason='Discovered checkpoints and refuge travel validated by the server.'},
  combat={status='connected',reason='Automatic attacks, manual specials, dodge and Guardian Trials.'},
  coop={status='connected',reason='Join a nearby Guardian encounter at its altar.'},
  defenses={status='connected',reason='Register an offline defense or challenge a UserId at the refuge.'},
  profile={status='read-only',reason='Collection, discoveries, Guardian wins, captures and trophies.'},
  quests={status='read-only',reason='Objectives reflect existing discoveries and Guardian wins; no claimable quest reward service.'},
  settings={status='connected',reason='Validated UI preferences stored with the existing profile.'},
  sanctuary={status='connected',reason='Assigned plots, three Blossom gates and return travel share the mountain profile; incubation and training use existing services.'},
  habitats={status='connected',reason='Own-plot assign, swap, collect, bank, upgrade, attune and cosmetic actions.'},
  partyInvites={status='unavailable',reason='No party finder, invitation or readiness backend.'},
  dailyRewards={status='unavailable',reason='No daily reward or quest reward backend.'},
  rankings={status='unavailable',reason='No server ranking service.'},
  badges={status='unavailable',reason='No badge award service for this mountain.'},
  titles={status='unavailable',reason='No title ownership or equip service.'},
  shop={status='partial',reason='Meadow Egg for coins with server receipts; Robux items stay disabled.'},
 }
end
function P.combatVisible(battle,ready,hubOpen)
 return ready==true and type(battle)=='table' and not hubOpen
end
function P.layout(width,height,largeText)
 local w=if finite(width) then math.max(1,width) else 667
 local h=if finite(height) then math.max(1,height) else 339
 local compact=h<500
 local phone=w<900 or compact
 local margin=if compact then 12 else 20
 local hubWidth=math.max(1,math.min(1040,w-margin*2))
 local hubHeight=math.max(1,math.min(760,h-margin*2))
 local narrow=w<560
 local teamBottom=if narrow then 176 else 12
 local teamWidth=math.max(1,math.min(if largeText then 324 else 300,if narrow then w-24 else w-360))
 return {compact=compact,phone=phone,sidebarWidth=if phone then 56 else 176,
  hubWidth=hubWidth,hubHeight=hubHeight,columns=math.max(1,math.floor((hubWidth-32)/(if largeText then 200 else 164))),
  teamWidth=teamWidth,teamBottom=math.min(teamBottom,math.max(0,h-160)),
  actionBottom=math.min(teamBottom+100,math.max(0,h-48))}
end
-- Glassbloom HUD geometry (climb&collect/design/hud-glassbloom-intel.md §2 HUD builders + §3 zones; plan §15 G2/G6-G9).
-- Every px is the board's 844x390 value at HUD scale M, in the HUD root's VIRTUAL space: the HUD root carries the one UIScale,
-- so real px = virtual px x scale. Inputs are REAL safe-root px: w,h = root size; obstacles = native TouchGui rects
-- ({x,y,w,h,kind='jump'|'stick'|'dynamic'}); topbar = Roblox's row (TopbarInset) in root coordinates (y < 0 when the row
-- sits above the root); opts = {scale, screen (full screen rect in root coords), coinW, edgeW, abilityW}.
P.hudScales={[0]=.85,[.5]=1,[1]=1.15} -- G2: hudScale pref 0/.5/1 = S/M/L
-- Narrowest virtual width the board geometry fits: the carry portrait's right edge (W/2+186) meets the sprint orb (W-150).
P.hudMinWidth=672
function P.hudScale(pref,w)
 local s=P.hudScales[pref] or 1
 if finite(w) and w>0 then s=math.min(s,math.max(P.hudScales[0],w/P.hudMinWidth)) end
 return s
end
local function rect(x,y,rw,rh) return {x=x,y=y,w=rw,h=rh} end
local function over(a,b) return a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h end
P.overlap=over
-- Native touch controls are anchored to the screen corners (jump bottom-right, thumbsticks bottom-left). Measure them from
-- the gui's own box (ref) so a resized root (audits) keeps them at the same corner distance; equals the plain offset when
-- the root fills the gui. abs/size/ref = {x,y,w,h} absolute boxes; root = {x,y,w,h} of the HUD root.
function P.nativeRect(o,ref,root,right)
 local dy=(ref.y+ref.h)-(o.y+o.h)
 local x=if right then root.w-((ref.x+ref.w)-(o.x+o.w))-o.w else o.x-ref.x
 return {x=x,y=root.h-dy-o.h,w=o.w,h=o.h}
end
function P.hudLayout(w,h,obstacles,touch,topbar,opts)
 opts=opts or {}
 local s=if finite(opts.scale) and opts.scale>0 then opts.scale else 1
 local W,H=w/s,h/s
 local sr=opts.screen or rect(0,0,w,h)
 local scr=rect(sr.x/s,sr.y/s,sr.w/s,sr.h/s)
 local bar=type(topbar)=='table' and topbar.w>0 and topbar.h>=44*s
 -- Zones (§3, full-screen px): core C = x < max(116, TopbarInset.Min.X), y < max(56, TopbarInset.Max.Y); thumbstick
 -- T = left 30 % x bottom 48 %; keep-clear M = x 28-72 %, y 24-70 %.
 local cx=math.max(116,if bar then topbar.x-sr.x else 0);local cy=math.max(56,if bar then topbar.y+topbar.h-sr.y else 0)
 local Z={S=scr,C=rect(scr.x,scr.y,cx/s,cy/s),T=rect(scr.x,scr.y+.52*scr.h,.30*scr.w,.48*scr.h),M=rect(scr.x+.28*scr.w,scr.y+.24*scr.h,.44*scr.w,.46*scr.h)}
 local obs={}
 for _,o in ipairs(obstacles or {}) do if o.kind~='dynamic' then table.insert(obs,rect(o.x/s,o.y/s,o.w/s,o.h/s)) end end
 -- B.tr (L97-100): coin pill h34 + gap 8 + gear 44, flush right; in Roblox's row level with the core buttons (HUD v2 measured
 -- them 12 px below the row top), else AP(1,0) at (1,-12, 0,7).
 local coinW=opts.coinW or 103 -- est.: B.tr box ~155 - gear 44 - gap 8
 local trW=coinW+8+44
 local edge,trY,inBar=W-12,7,false
 if bar then
  local e=math.min(w,topbar.x+topbar.w)/s-12
  if e-trW>=topbar.x/s then edge=e;trY=(topbar.y+math.min(12,topbar.h-44*s))/s;inBar=true end
 end
 local tr=rect(edge-trW,trY,trW,44)
 -- B.rail (L101-106): x 14, w 22, top 14 below the core zone (board 70 = 56+14), bottom 10 above the thumbstick zone.
 -- G9: 6 section nodes 12 + summit 15 (10/13 when the rail is under 110), top = summit, spread space-between.
 local railTop=Z.C.y+Z.C.h+14;local railH=Z.T.y-10-railTop
 local small=railH<110;local node=if small then 10 else 12;local summit=if small then 13 else 15
 local gap=(railH-6*node-summit)/6
 local nodes={[7]=rect((22-summit)/2,0,summit,summit)};local ny=summit+gap
 for k=6,1,-1 do nodes[k]=rect((22-node)/2,ny,node,node);ny+=node+gap end
 -- B.dock (L110-115): AP(.5,1) (.5,0, 1,-10); glass border 2 + padding 6, 42 px buttons, gap 6 (5 = 250x58, chase 3 = 154x58).
 local function dockRect(n) local dw=2*8+n*42+(n-1)*6;return rect(W/2-dw/2,H-10-58,dw,58) end
 local dock,dockChase=dockRect(5),dockRect(3)
 local dockButtons={};for i=1,5 do dockButtons[i]=rect(dock.x+8+(i-1)*48,dock.y+8,42,42) end
 -- Orbs (L123-124): sprint 54 at AP(1,1) (1,-96, 1,-20); bat 52 at (1,-20, 1,-96). They cleared the board's 70 px jump orb by
 -- 10 px, so the same 10 px clearance moves them off a native jump/thumbstick (G10): sprint left, bat up.
 local sprint=rect(W-96-54,H-20-54,54,54);local bat=rect(W-20-52,H-96-52,52,52)
 for _,o in ipairs(obs) do if over(sprint,o) then sprint.x=math.min(sprint.x,o.x-10-54) end end
 for _,o in ipairs(obs) do if over(bat,o) then bat.y=math.min(bat.y,o.y-10-52) end end
 -- G8: pick-up orb = bat recipe 52, 10 px above the bat orb (board bottom -158).
 local pickup=rect(bat.x,bat.y-10-52,52,52)
 for _,o in ipairs(obs) do if over(pickup,o) then pickup.y=math.min(pickup.y,o.y-10-52) end end
 -- G6 battle: 3 sprint-recipe orbs 54 in a dock glass (r30, border 2 + padding 6, gap 6) in the dock slot; Dodge = bat slot;
 -- Ability = glass chip h27 above the dock (4 px, the XP line's clearance); boss bar = banner glass in the tier-2 slot.
 local team=rect(W/2-95,H-10-70,190,70)
 local slots={};for i=1,3 do slots[i]=rect(team.x+8+(i-1)*60,team.y+8,54,54) end
 local aw=opts.abilityW or 84
 local ability=rect(W/2-aw/2,team.y-4-27,aw,27)
 -- Where the chip would enter the keep-clear zone (short phones), it slides right of M on the same line.
 if over(ability,Z.M) then ability.x=Z.M.x+Z.M.w+6 end
 -- B.cp (L125-128): AP(0,1) (.5,134, 1,-10), 52x62. B.edge (L129): AP(1,0) (1,-8, .36,0), h36, w ~100 est.
 local portrait=rect(W/2+134,H-10-62,52,62)
 local ew=opts.edgeW or 100
 local edgeArrow=rect(W-8-ew,.36*H,ew,36)
 -- Transient slots (§4): tier 1 under the coin pill (board y 60 = row 7 + 53); tier 2 band (banner 62, pop-up 60); RUN! top
 -- .19 (LG 104, line 1.2 = 125; awake pill h27, 6 below); moment top .30 (LG 64 line 77; sub pill h20, 8 below). Widths
 -- cap at the core column so a centred/right-anchored message never reaches C.
 local band=W-2*(Z.C.x+Z.C.w)
 local runY=scr.y+.19*scr.h;local momentY=scr.y+.30*scr.h
 return {
  scale=s,topbar=inBar,zones=Z,railFits=gap>=0,railNode=node,railSummit=summit,
  tr=tr,coin=rect(tr.x,trY+5,coinW,34),gear=rect(edge-44,trY,44,44),
  rail=rect(14,railTop,22,railH),railNodes=nodes,railLabel=rect(42,scr.y+.26*scr.h+20,0,25),
  dock=dock,dockChase=dockChase,dockButtons=dockButtons,xpLine=rect(W/2-118,H-72-6,236,6),
  sprint=sprint,bat=bat,pickup=pickup,dodge=bat,team=team,slots=slots,ability=ability,
  portrait=portrait,edge=edgeArrow,
  toast=rect(edge,trY+53,0,30),toastMax=math.max(0,edge-(Z.C.x+Z.C.w)),
  banner=rect(W/2,trY+55,0,59),carryPop=rect(W/2,trY+53,0,78),boss=rect(W/2,trY+55,0,76),bandMax=math.max(0,band),
  run=rect(0,runY,W,125),awake=rect(W/2,runY+125+6,0,27),shock=rect(W/2-90,scr.y+.22*scr.h-90,180,180),
  moment=rect(0,momentY,W,77),momentSub=rect(W/2,momentY+77+8,0,20),collect=rect(W/2-95,momentY+77+8+20+8,190,46),
  -- B.pcard (L170-174, G7): AP(0,1) (.5,-125, 1,-78); widened to the 5-button launcher row: 2+12+5x42+4x6+12+2 = 262; height
  -- 2+10+48 (ring row)+10 (gap)+42 (launcher)+10+2 = 124.
  card=rect(W/2-125,H-78-124,262,124),
  screen=scr,
 }
end
return P
