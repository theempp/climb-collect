local Rules=require(game.ReplicatedStorage.MountainShared.GuardianRules)
local Config=require(game.ReplicatedStorage.MountainShared.RaidConfig)
local G={}
function G.new(context)
 local states,models,homes,lastTick={},{},{},context.clock()
 local service={}
 for k=1,6 do
  states[k]=Rules.new(k,lastTick)
  local model=context.world.Encounters:FindFirstChild('Guardian_'..k)
  models[k]=model;homes[k]=model and model:GetPivot()
 end
 function service.alert(k,userId,eggId,now)
  if not states[k] then return end
  Rules.alert(states[k],userId,eggId,now or context.clock())
  if context.warning then context.warning(userId,k) end
 end
 function service.position(k) return models[k] and models[k]:GetPivot().Position-Vector3.new(0,context.rootHeight(k),0) end
 function service.resting(k) return context.clock()<states[k].restUntil end
 function service.normalWin(k,contributors)
  local _,effects=Rules.normalWin(states[k],contributors,context.clock())
  return effects
 end
 function service.remove(player)
  for _,state in pairs(states) do state.threats[player.UserId]=nil end
 end
 function service.tick(now)
  local dt=math.min(.25,now-lastTick);lastTick=now
  local players=context.players()
  for k,state in ipairs(states) do
   local model=models[k];if not model or not model.PrimaryPart then continue end
   local current=model:GetPivot();local observations={};local targets={}
   for _,player in ipairs(players) do
    local r=context.root(player);local p=context.profile(player)
    if r and p and context.alive(player) and not context.protected(player) then
     -- Measure from the defender's feet, including height: a ledge above is not a catch.
     local delta=r.Position-(current.Position-Vector3.new(0,context.rootHeight(k),0))
     observations[player.UserId]={alive=true,inside=context.inside(k,r.Position),distance=delta.Magnitude,breaking=p.run and p.run.section==k and p.run.phase=='breaking'}
     targets[player.UserId]={player=player,root=r}
    end
   end
   local _,effects=Rules.step(state,observations,now)
   local target=state.target and targets[state.target]
   local destination=if target then target.root.Position else homes[k].Position
   local delta=Vector3.new(destination.X-current.X,0,destination.Z-current.Z)
   local speed=Config.section(k).guardianSpeed*(if state.phase=='approaching' then .55 elseif state.phase=='resting' then .5 else 1)
   if delta.Magnitude>.5 then
    local nextPosition=current.Position+delta.Unit*math.min(delta.Magnitude,speed*dt)
    local ground=context.ground(nextPosition,k)
    if ground and context.inside(k,ground) then
     nextPosition=Vector3.new(nextPosition.X,ground.Y+context.rootHeight(k),nextPosition.Z)
     model:PivotTo(CFrame.lookAt(nextPosition,nextPosition+delta.Unit))
    end
   end
   model:SetAttribute('GuardianState',state.phase);model:SetAttribute('TargetUserId',state.target)
   model:SetAttribute('RestUntil',workspace:GetServerTimeNow()+math.max(0,state.restUntil-now))
   if state.phase=='approaching' then model:SetAttribute('TellUntil',workspace:GetServerTimeNow()+.5) end
   if effects.attack and targets[effects.attack] then context.catch(targets[effects.attack].player,k) end
  end
 end
 service.states=states
 return service
end
return G
