from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'src/core/server/Gear.luau'
s=p.read_text()
a=s.index('function Gear.hasKit')
b=s.index('local function atSite',a)
s=s[:a]+'''function Gear.hasKit(_,id)
 return id=="headlamp" or id=="axe" or id=="crampons"
end

''' +s[b:]
s=s.replace('C.CLIMB.stamina + Gear.trainingBonus(s)','Gear.staminaMax(s)')
a=s.index('function Gear.trainingBonus')
s=s[:a]+'''function Gear.trainingBonus(s)
 local tr=g(s).training
 local legacy=0 for i=1,tr.level or 0 do legacy+=C.TRAINING.gains[i] or 0 end
 local practiced=0 for i,gain in ipairs(C.PRACTICE.gains) do if tr.completed and tr.completed[tostring(i)] then practiced+=gain end end
 return math.max(legacy,practiced)
end
function Gear.staminaMax(s)
 return math.min(C.PRACTICE.staminaCap,C.CLIMB.stamina+math.max(0,s.data.level-1)*3+Gear.trainingBonus(s))
end
function Gear.state(plr,st)
 local s=ctx.sessions[plr] if not s then return end
 local gs=g(s)
 st.gear={points=gs.points,owned=gs.owned,equipped=gs.equipped,summits=gs.summits,kit={headlamp={owned=true},axe={owned=true},crampons={owned=true}},training={level=gs.training.level,max=3,bonus=Gear.trainingBonus(s)},staminaMax=Gear.staminaMax(s)}
end
function Gear.init(c)
 ctx=c C=c.C ctx.Gear=Gear
 -- Currency and owned cosmetics are retained. No shop/refill/purchase handlers or prompts are registered.
 ctx.on("bank",function(plr) Gear.dress(plr) end)
 if ctx.devHandlers then ctx.devHandlers.gearGrant=function(plr,p)
  local s=ctx.sessions[plr] if s then s.data.coins+=math.floor(tonumber(p.coins) or 0) g(s).points+=math.floor(tonumber(p.points) or 0) s.dirty=true ctx.push(plr) end
 end end
end
function Gear.onLoaded(plr) Gear.dress(plr) end
function Gear.onCharacter(plr) task.wait(0.5) Gear.dress(plr) end
function Gear.onLeave(_) end
return Gear
'''
s=s.replace('-- the weather client turns it on at night','-- traversal client uses actual darkness + player preference')
p.write_text(s,encoding='utf-8')
p=root/'src/core/shared/CoreConfig.luau'
s=p.read_text()
a=s.index('\t-- v4 P4 (run 2, PROPOSED): kit + canister')
b=s.index('\n}',a)
s=s[:a]+''' -- Surface equipment multipliers are owned by TraversalConfig (no altitude survival rules).
 cramponDrain = 0.8,
 ropeDrain = 0.5,'''+s[b:]
s=s.replace('C.CANISTER = { price = 150, cur = "coins", max = 3, campRefill = true } -- one free refill at each camp per trip','-- Legacy canister counts remain in profile migration only; there is no consumable survival system.')
s=s.replace('C.SHOP_SITES = { "Market", "Forge" } -- Foothold districts that open the shop (existing buildings, no new geometry)','C.SHOP_SITES = {} -- shops postponed; legacy cosmetic definitions preserve existing owned appearances.')
s=s.replace('return C','''C.PRACTICE = {
 costs = { 0, 25, 60 },
 gains = { 6, 7, 7 },
 staminaCap = 140,
 labels = { "Rhythm & footholds", "Anchors & recovery", "Fork choices" },
}
return C''')
p.write_text(s,encoding='utf-8')
print('Automatic equipment, finite stamina cap, no commerce or oxygen paths')
