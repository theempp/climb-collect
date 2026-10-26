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
  shop={status='unavailable',reason='No approved product catalog, receipt or entitlement backend.'},
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
-- Safe-root coordinates. Native bounds are supplied by the actual TouchGui.
function P.horizontalNavigation(height,touch) return height<550 or touch==true end
function P.hudLayout(w,h,obstacles,touch)
 local short=h<400
 local left,right=12,w-12
 for _,o in ipairs(obstacles or {}) do
  if o.y+o.h>h-100 then
   if o.x<w/2 then left=math.max(left,math.min(o.x+o.w+8,w*.43))
   else right=math.min(right,o.x-8) end
  end
 end
 local tw=math.min(if short then 258 else 330,right-left)
 local center=(left+right)/2
 local function rect(x,y,rw,rh) return {x=x,y=y,w=rw,h=rh} end
 local horizontal=P.horizontalNavigation(h,touch==true or #(obstacles or {})>0)
 local actionY=math.min(h-190,h-((if short then 140 else 170)+54))
 for _,o in ipairs(obstacles or {}) do if o.x>w/2 then actionY=math.min(actionY,o.y-108) end end
 return {
  short=short,
  horizontalNavigation=horizontal,
  navigation=if horizontal then rect(100,if h<550 then 54 else 60,math.min(w-110,696),if h<550 then 50 else 82) else rect(12,140,184,326),
  status=rect(12,8,if w<900 then 230 else 290,44),
  journey=rect(w-(if short then 232 else 272)-12,8,if short then 232 else 272,if short then 64 else 78),
  menu=rect(12,if short then 54 else 60,80,if short then 48 else 70),
  quickCreatures=rect(100,if short then 54 else 60,76,if short then 48 else 70),
  quickMountain=rect(184,if short then 54 else 60,76,if short then 48 else 70),
  team=rect(center-tw/2,h-(if short then 90 else 112),tw,if short then 76 else 94),
  context=rect(center-math.min(tw,250)/2,h-(if short then 144 else 168),math.min(tw,250),48),
  dodge=rect(w-106,actionY,94,48),
  ability=rect(w-208,actionY,94,48),
  sprint=rect(w-106,actionY+54,94,48),
 }
end
return P
