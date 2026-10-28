-- Caeloryn (Astral Crown Guardian) abilities 1-4. Names come from the Catalog; roles are LOCKED (decision §5):
-- 2 Gravity Choir = control (pull/push), 3 Constellation Accord = team shield, 4 Celestial Dominion = ultimate
-- (charged beam + star constructs). Numbers are PROPOSED, tuned for 1-2 players (duo parties).
local C=if script then require(script.Parent.Catalog) else require('./Catalog')
local A={species='caeloryn'}
A.abilities={
 {role='break',cooldown=12,damage=3},
 {role='control',cooldown=15,damage=2.5,weaken=6,delayAttack=2.5,pull=true},
 {role='team_shield',cooldown=18,damage=0,shield=.30,shieldSeconds=8,heal=20,radius=45},
 {role='ultimate',cooldown=45,charge=1.5,damage=6,constructs=3,constructDamage=.6,constructSeconds=4},
}
for i,a in ipairs(A.abilities) do a.index=i;a.name=C.byId.caeloryn.abilities[i] end
-- Pure resolution: what one cast does, given the caster's attack and the allies in range (caster included).
-- Combat applies the result; tests check the numbers. allies = list of ids within radius.
function A.resolve(index,attack,allies)
 local a=A.abilities[index];if not a or type(attack)~='number' or attack~=attack or attack<0 then return nil end
 local r={index=index,role=a.role,cooldown=a.cooldown,damage=attack*a.damage}
 if a.role=='control' then r.weaken=a.weaken;r.delayAttack=a.delayAttack;r.pull=true
 elseif a.role=='team_shield' then
  r.shieldTargets={};for i,id in ipairs(allies or {}) do if i<=2 then table.insert(r.shieldTargets,id) end end -- duo cap
  r.shield=a.shield;r.shieldSeconds=a.shieldSeconds;r.heal=a.heal
 elseif a.role=='ultimate' then
  r.charge=a.charge;r.constructs=a.constructs;r.constructDps=attack*a.constructDamage;r.constructSeconds=a.constructSeconds
  r.total=r.damage+r.constructs*r.constructDps*r.constructSeconds
 end
 return r
end
return A
