-- Strategy sensitivity, not human timing. Uses real transitions and no seed coins.
local R=require('../shared/Rules')
local T=R.tycoon
local checks=0
local function check(v,m) assert(v,m);checks+=1 end
local function drain(p)
 T.bank(p)
 while T.collect(p,0)>0 do T.bank(p) end
end
local function run(name,visit,order,training,acquisition)
 local p=R.newProfile(0);T.ensure(p,0)
 assert(T.assign(p,1,'c1',0));assert(T.assign(p,2,'c2',0))
 local spent,earned,trains=0,0,0
 local first,auto,full
 local function purchase(path,index,now)
  local q=T.quote(p,path,index)
  if q and q.ready and p.coins>=q.cost then
   assert(T.upgrade(p,path,index,now));spent+=q.cost;first=first or now
   if p.tycoon.levels.automation==5 then auto=auto or now end
   if p.tycoon.slots==8 then full=full or now end
   return true
  end
  return false
 end
 for now=10,48*3600,10 do
  local before=p.coins
  T.settle(p,now,false)
  if now%visit==0 then drain(p) end
  earned+=p.coins-before
  -- Explicit sensitivity: one free owned Common per hour, up to eight.
  -- This is NOT measured acquisition time or a change to game rewards.
  if acquisition and now%3600==0 and #p.creatures<8 then
   table.insert(p.creatures,{id='fixture'..now,species='mossbun',level=1,xp=0})
  end
  if now%visit==0 then
   if training and trains<10 and p.coins>=15 then
    p.coins-=15;spent+=15;trains+=1;R.addXP(p.creatures[1],80)
   end
   for _=1,100 do
    local bought=false
    for _,path in ipairs(order) do
     if path=='habitat' then
      for i=1,p.tycoon.slots do
       if p.tycoon.habitats[i].creature and purchase(path,i,now) then bought=true;break end
      end
     elseif path~='habitats' or p.tycoon.slots<#p.creatures then bought=purchase(path,nil,now) end
     if bought then break end
    end
    if not bought then break end
   end
   for i=1,math.min(p.tycoon.slots,#p.creatures) do
    if not p.tycoon.habitats[i].creature then assert(T.assign(p,i,p.creatures[i].id,now)) end
   end
  end
 end
 check(T.valid(p.tycoon),name..' valid')
 check(p.coins+spent==earned,name..' currency conservation')
 check(table.concat(p.team,',')=='c1,c2,c3',name..' team preserved')
 print(string.format('PROGRESSION %s visit=%dm first=%.2fm auto=%sh eight=%sh earned=%d spent=%d balance=%d slots=%d training=%d',name,visit/60,(first or 0)/60,auto and string.format('%.2f',auto/3600) or 'unreached',full and string.format('%.2f',full/3600) or 'unreached',earned,spent,p.coins,p.tycoon.slots,trains))
 return p
end
local orders={
 yield={'habitats','production','habitat','storage','banking','automation','bag'},
 automation={'automation','production','storage','banking','habitats','habitat','bag'},
 storage={'storage','bag','habitats','production','habitat','banking','automation'},
}
for _,visit in ipairs({60,15*60,60*60}) do
 for _,name in ipairs({'yield','automation','storage'}) do
  run(name,visit,orders[name],false,false)
 end
end
run('exploration-common-sensitivity',15*60,orders.yield,false,true)
run('training-first',15*60,orders.yield,true,true)
-- Creature training changes combat stats, not production rate: habitat upgrades do.
local p=R.newProfile(0);T.ensure(p,0);T.assign(p,1,'c1',0)
local rate=T.rate(p,1);R.addXP(p.creatures[1],10000)
check(T.rate(p,1)==rate,'training does not multiply egg income')
print('PASS '..checks..' tycoon progression checks')
