-- Async defense snapshots: no online defender or alteration of their inventory is required.
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local R=require(game.ReplicatedStorage.MountainShared.Rules)
local Store=require(script.Parent.Store)
local S={dailyCoinWins=5}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local db=if game:GetService('RunService'):IsStudio() then Store.memory() else Store.datastore('MountainEmpire_Defenses_v1')
function S.snapshot(p,userId)
 local team={}
 for _,c in ipairs(R.battleTeam(p)) do table.insert(team,{species=c.species,level=c.level,xp=0,specialization=c.specialization}) end
 return {userId=userId,team=team,timestamp=os.time(),version=1}
end
function S.register(p,userId)
 local snap=S.snapshot(p,userId)
 local ok=db:update('u'..userId,function() return snap end);return ok
end
local function score(team)
 local hp,atk=0,0
 for _,c in ipairs(team) do local stats=R.stats(c);hp+=stats.health;atk+=stats.attack end
 return hp,atk
end
function S.challenge(p,userId,target)
 local now=os.time()
 if now<p.competitionAt then return false,'Defense challenge available in '..(p.competitionAt-now)..'s.' end
 if type(target)~='number' or target%1~=0 or target<0 or target>9007199254740991 or target==userId then return false,'Enter another player’s numeric UserId, or 0 for practice.' end
 local defense
 if target==0 then
  defense={team={{species='mossbun',level=3},{species='petalyn',level=3},{species='fernox',level=3}},userId=0}
 else
  local ok,snap=db:read('u'..target)
  if not ok or not snap or snap.version~=1 or type(snap.team)~='table' or #snap.team<1 or #snap.team>3 then return false,'No saved defense available for that player.' end
  for _,c in ipairs(snap.team) do if not C.byId[c.species] or type(c.level)~='number' or c.level<1 or c.level>50 then return false,'Defense snapshot is invalid.' end end
  defense=snap
 end
 local attack=S.snapshot(p,userId)
 local ah,aa=score(attack.team);local dh,da=score(defense.team)
 local rounds=0
 while ah>0 and dh>0 and rounds<100 do ah-=da;dh-=aa;rounds+=1 end
 local won=dh<=0 and ah>0
 p.competitionAt=now+120
 local coins=0
 if won then
  p.trophies+=10
  -- Q4: 5 coin-paying wins per UTC day (practice and snapshot together); trophies are unchanged. The day only moves forward.
  local c=if type(p.competition)=='table' then p.competition else {}
  local today=math.floor(now/86400);local day=if finite(c.day) and c.day>=0 then math.floor(c.day) else 0
  local wins=if finite(c.wins) then math.clamp(math.floor(c.wins),0,S.dailyCoinWins) else 0
  if day>today+1 then day=today end
  if today>day then day=today;wins=0 end
  if wins<S.dailyCoinWins then wins+=1;coins=35;p.coins+=coins end
  p.competition={day=day,wins=wins}
 end
 return true,{won=won,rounds=rounds,trophies=if won then 10 else 0,coins=coins,opponent=target,practice=target==0}
end
return S
