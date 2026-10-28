-- Pure bat rules. All numbers are provisional local-playtest tuning, not approved targets.
-- Owner rules (2026-10-26): a bat hit knocks a carrier flying and drops the unsecured creature for 3 s;
-- each completed section index set unlocks that section's bat; coins upgrade the equipped bat.
local C=if script then require(script.Parent.Catalog) else require('./Catalog')
local B={version=1,provisional=true,swingCooldown=1.5,victimCooldown=8,dropSeconds=3,grabRange=10,maxLevel=10,
 upgradeBase=120,levelKnockback=.06,levelReach=.2,lift=.45,stunSeconds=.9,sanctuaryProtected=true,checkpointRadius=20}
-- Starter bat uses Blossom's catalog rock tone; section bats use their kingdom's catalog accent and material.
B.bats={{id='trail',name='Trail Bat',kingdom=0,knockback=55,reach=7,color=C.kingdoms[1].rock,trail=C.kingdoms[1].accent,material='Wood'}}
for k,kingdom in ipairs(C.kingdoms) do
 table.insert(B.bats,{id=kingdom.id,name=kingdom.name:match('^%S+')..' Bat',kingdom=k,knockback=55+k*8,reach=7+k*.5,color=kingdom.accent,trail=kingdom.color,material=kingdom.material})
end
B.byId={};for _,b in ipairs(B.bats) do B.byId[b.id]=b end
local function level(n) return type(n)=='number' and n==n and n%1==0 and n>=1 and n<=B.maxLevel end
function B.normalize(p)
 local s=type(p.bats)=='table' and p.bats or {}
 local levels={trail=1}
 if type(s.levels)=='table' then for id,n in pairs(s.levels) do if B.byId[id] and level(n) then levels[id]=n end end end
 p.bats={equipped=if type(s.equipped)=='string' and levels[s.equipped] then s.equipped else 'trail',levels=levels}
 return p.bats
end
-- Index progress for one section: distinct owned species of that kingdom. Robux creatures never count (D8: no paid power in theft).
function B.setProgress(p,k)
 local seen,count={},0
 for _,c in ipairs(p.creatures or {}) do local s=C.byId[c.species];if s and c.origin~='robux' and s.kingdom==k and s.rarity~='Legendary' and not seen[s.id] then seen[s.id]=true;count+=1 end end
 local total=0;for _,s in ipairs(C.species) do if s.kingdom==k then total+=1 end end
 return count,total
end
function B.unlocked(p,id)
 local b=B.byId[id];if not b then return false end
 if b.kingdom==0 then return true end
 local have,total=B.setProgress(p,b.kingdom);return have>=total
end
-- Completing a set grants the bat at level 1; called after any collection change.
function B.grantUnlocks(p)
 local s=B.normalize(p);local granted={}
 for _,b in ipairs(B.bats) do if not s.levels[b.id] and B.unlocked(p,b.id) then s.levels[b.id]=1;table.insert(granted,b.id) end end
 return granted
end
function B.equip(p,id)
 local s=B.normalize(p);if not s.levels[id] then return false end
 s.equipped=id;return true
end
function B.upgradeCost(n) return B.upgradeBase*n*n end
function B.upgrade(p,id)
 local s=B.normalize(p);local n=s.levels[id]
 if not n or s.equipped~=id then return false,'not_equipped' end
 if n>=B.maxLevel then return false,'max' end
 local cost=B.upgradeCost(n);if type(p.coins)~='number' or p.coins<cost then return false,'coins' end
 p.coins-=cost;s.levels[id]=n+1;return true,cost
end
function B.stats(id,n)
 local b=B.byId[id] or B.byId.trail;n=if level(n) then n else 1
 return {knockback=b.knockback*(1+B.levelKnockback*(n-1)),reach=b.reach+B.levelReach*(n-1)}
end
function B.equippedStats(p)
 local s=B.normalize(p);return B.stats(s.equipped,s.levels[s.equipped]),s.equipped
end
-- Hit validation, independent of world queries. ctx: now, distance, facing (dot), attacker/target zones.
function B.canHit(state,ctx)
 if ctx.attackerSafeZone or ctx.targetSafeZone then return false,'safe_zone' end
 if ctx.targetProtected then return false,'protected' end
 if ctx.now<(state.readyAt or 0) then return false,'cooldown' end
 if ctx.distance>ctx.reach then return false,'too_far' end
 if ctx.facing<.25 then return false,'facing' end
 local last=state.victims and state.victims[ctx.target]
 if last and ctx.now-last<B.victimCooldown then return false,'same_victim' end
 return true
end
function B.recordSwing(state,now) state.readyAt=now+B.swingCooldown end
function B.recordHit(state,target,now)
 state.readyAt=now+B.swingCooldown;state.victims=state.victims or {};state.victims[target]=now
 for id,t in pairs(state.victims) do if now-t>=B.victimCooldown then state.victims[id]=nil end end
end
return B
