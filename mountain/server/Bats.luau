-- Server-authoritative bats: swing validation, knockback, 3 s dropped-creature scramble and held bat models.
local BatRules=require(game.ReplicatedStorage.MountainShared.BatRules)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local TweenService=game:GetService('TweenService')
local Bats={}
function Bats.new(context)
 local states,models,drops={},{},{}
 local service={}
 local function color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
 local function hand(character) return character:FindFirstChild('RightHand') or character:FindFirstChild('Right Arm') end
 -- One held bat per character; rebuilt when the equipped bat changes.
 function service.equip(player)
  local p=context.profile(player);local character=player.Character;local grip=character and hand(character)
  if models[player] then models[player].model:Destroy();models[player]=nil end
  if not p or not grip then return end
  local _,id=BatRules.equippedStats(p);local def=BatRules.byId[id]
  local model=Instance.new('Model');model.Name='Bat'
  local handle=Instance.new('Part');handle.Name='Handle';handle.Size=Vector3.new(.35,1.6,.35);handle.Color=color(C.kingdoms[1].rock);handle.Material=Enum.Material.Wood
  local barrel=Instance.new('Part');barrel.Name='Barrel';barrel.Size=Vector3.new(.7,2.4,.7);barrel.Color=color(def.color);barrel.Material=Enum.Material[def.material] or Enum.Material.Wood
  for _,part in ipairs({handle,barrel}) do part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Massless=true;part.Anchored=false;part.Parent=model end
  local join=Instance.new('WeldConstraint');barrel.CFrame=handle.CFrame*CFrame.new(0,2,0);join.Part0=handle;join.Part1=barrel;join.Parent=handle
  local a0=Instance.new('Attachment');a0.Position=Vector3.new(0,-1.1,0);a0.Parent=barrel
  local a1=Instance.new('Attachment');a1.Position=Vector3.new(0,1.1,0);a1.Parent=barrel
  local trail=Instance.new('Trail');trail.Attachment0=a0;trail.Attachment1=a1;trail.Color=ColorSequence.new(color(def.trail));trail.Lifetime=.18;trail.Enabled=false;trail.Parent=barrel
  local weld=Instance.new('Weld');weld.Part0=grip;weld.Part1=handle;weld.C0=CFrame.new(0,-grip.Size.Y/2,0)*CFrame.Angles(math.rad(-90),0,0);weld.Parent=handle
  model.PrimaryPart=handle;model.Parent=character
  models[player]={model=model,weld=weld,rest=weld.C0,trail=trail,id=id}
 end
 local function swingVisual(player)
  local m=models[player];if not m or not m.model.Parent then return end
  m.trail.Enabled=true;if player.Character then player.Character:SetAttribute('BatSwingAt',workspace:GetServerTimeNow()) end
  local out=TweenService:Create(m.weld,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{C0=m.rest*CFrame.Angles(0,0,math.rad(-120))})
  out:Play();out.Completed:Once(function()
   if m.weld.Parent then TweenService:Create(m.weld,TweenInfo.new(.2),{C0=m.rest}):Play() end
   task.delay(.15,function() m.trail.Enabled=false end)
  end)
 end
 local function clearDrop(drop)
  drops[drop.id]=nil
  if drop.part then drop.part:Destroy() end
 end
 local function place(drop,position)
  local part=Instance.new('Part');part.Name='Dropped creature';part.Size=Vector3.new(3,3,3);part.Transparency=1;part.Anchored=true;part.CanCollide=false;part.CFrame=CFrame.new(position)
  part:SetAttribute('Kind','DroppedCreature');part:SetAttribute('Id',drop.id)
  local q=Instance.new('ProximityPrompt');q.ActionText='Grab';q.ObjectText=C.byId[drop.snapshot.species].name;q.HoldDuration=.25;q.MaxActivationDistance=BatRules.grabRange;q.RequiresLineOfSight=false;q.Parent=part
  part.Parent=context.folder
  if context.creatureModel then local model=context.creatureModel(part,drop.snapshot.species,position);if model then model.Parent=part end end
  drop.part=part
 end
 function service.swing(player)
  local p=context.profile(player);local rr=context.root(player)
  if not p or not rr or not context.alive(player) then return false,'unavailable' end
  if p.run and p.run.phase=='carried' then return false,'hands_full' end
  local now=context.clock();local state=states[player] or {};states[player]=state
  if now<(state.readyAt or 0) then return false,'cooldown' end
  local stats=BatRules.equippedStats(p)
  BatRules.recordSwing(state,now);swingVisual(player)
  local best,bestDistance=nil,math.huge
  for _,other in ipairs(context.players()) do
   local orr=other~=player and context.root(other)
   if orr and context.alive(other) then
    local offset=orr.Position-rr.Position;local distance=offset.Magnitude
    if distance<bestDistance and distance<=stats.reach+1 then best=other;bestDistance=distance end
   end
  end
  if not best then return true,'miss' end
  local orr=context.root(best);local offset=orr.Position-rr.Position
  local flat=Vector3.new(offset.X,0,offset.Z);local dir=if flat.Magnitude>.01 then flat.Unit else rr.CFrame.LookVector
  local ok,reason=BatRules.canHit(state,{now=now,distance=bestDistance,reach=stats.reach,facing=rr.CFrame.LookVector:Dot(dir),target=best.UserId,
   attackerSafeZone=context.safeZone(player),targetSafeZone=context.safeZone(best),targetProtected=context.protected(best)})
  if not ok then return true,reason end
  BatRules.recordHit(state,best.UserId,now)
  context.knock(best,dir*stats.knockback+Vector3.new(0,stats.knockback*BatRules.lift,0),BatRules.stunSeconds)
  local snapshot=context.raids.drop(best)
  if snapshot then
   local drop={id=context.guid(),snapshot=snapshot,from=best,expires=now+BatRules.dropSeconds}
   drops[drop.id]=drop;place(drop,orr.Position+Vector3.new(0,1,0))
   context.notify(best,'Knocked! Your '..C.byId[snapshot.species].name..' dropped — grab it back!')
   context.notify(player,'Hit! Grab the '..C.byId[snapshot.species].name..' before it escapes.')
  end
  return true,'hit'
 end
 function service.grab(player,id)
  local drop=drops[id];local rr=context.root(player)
  if not drop or not rr or not context.alive(player) or not drop.part then return false,'gone' end
  if (rr.Position-drop.part.Position).Magnitude>BatRules.grabRange+1 then return false,'too_far' end
  local ok,reason=context.raids.adopt(player,drop.snapshot,drop.part.Position)
  if not ok then return false,reason end
  clearDrop(drop)
  if player~=drop.from then context.notify(drop.from,'Your creature was taken. Unsecured creatures stay at risk until the sanctuary gate.') end
  return true
 end
 function service.tick(now)
  for _,drop in pairs(drops) do
   if now>=drop.expires then
    local back=drop.from.Parent~=nil and context.alive(drop.from) and context.raids.adopt(drop.from,drop.snapshot,drop.part and drop.part.Position or Vector3.zero)
    if not back and drop.from.Parent~=nil then context.notify(drop.from,'Your dropped creature escaped.') end
    clearDrop(drop)
   end
  end
 end
 function service.remove(player)
  states[player]=nil
  if models[player] then models[player].model:Destroy();models[player]=nil end
  for _,drop in pairs(drops) do if drop.from==player then drop.from={Parent=nil} end end
 end
 function service.snapshot(p)
  local s=BatRules.normalize(p);local list={}
  for _,b in ipairs(BatRules.bats) do
   local have,total=if b.kingdom>0 then BatRules.setProgress(p,b.kingdom) else 0,0
   local level=s.levels[b.id];local stats=BatRules.stats(b.id,level or 1)
   table.insert(list,{id=b.id,name=b.name,kingdom=b.kingdom,level=level,owned=level~=nil,equipped=s.equipped==b.id,have=have,total=total,
    knockback=math.floor(stats.knockback),reach=math.floor(stats.reach*10)/10,cost=if level and level<BatRules.maxLevel then BatRules.upgradeCost(level) else nil})
  end
  return list
 end
 return service
end
return Bats
