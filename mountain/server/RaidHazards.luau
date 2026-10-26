local Rules=require(game.ReplicatedStorage.MountainShared.HazardRules)
local Config=require(game.ReplicatedStorage.MountainShared.RaidConfig)
local H={}
function H.new(context)
 local hazards={};local service={}
 for _,p in ipairs(context.world.Dynamics:GetChildren()) do if p:GetAttribute('Kind')=='RaidHazard' then
  local art={};for _,a in ipairs(p:GetDescendants()) do if a:IsA('BasePart') then table.insert(art,{part=a,cf=a.CFrame}) end end
  table.insert(hazards,{part=p,k=p:GetAttribute('Kingdom'),hits={},art=art})
 end end
 function service.remove(player) for _,h in ipairs(hazards) do h.hits[player]=nil end end
 function service.tick(now)
  for _,h in ipairs(hazards) do
   local phase,cycle=Rules.sample(h.k,now);local active=phase=='active';local config=Config.section(h.k)
   local p=h.part;p:SetAttribute('Phase',phase);p.Transparency=if active then .15 elseif phase=='warning' then .4+.15*math.sin(now*10) else .9
   for i,a in ipairs(h.art) do
    a.part.Transparency=if active then .05 elseif phase=='warning' then .2 else .65
    local offset=Vector3.zero
    if active then
     if h.k==1 then offset=Vector3.new(math.sin(now*7)*5,1,0)
     elseif h.k==2 then offset=Vector3.new(0,1,math.sin(now*8)*4)
     elseif h.k==3 then offset=Vector3.new(0,-10,0)
     elseif h.k==5 then offset=Vector3.new(0,2+math.sin(now*13+i),0)
     elseif h.k==6 then offset=Vector3.new(0,2+math.sin(now*4+i),0) end
    end
    a.part.CFrame=a.cf+offset
    if h.k==3 then a.part.CanCollide=not active end
   end
   if active then for _,player in ipairs(context.players()) do
    local r=context.root(player);local humanoid=context.alive(player)
    if r and humanoid and not context.protected(player) and not context.inSanctuary(r.Position) and h.hits[player]~=cycle then
     local q=p.CFrame:PointToObjectSpace(r.Position)
     if Rules.contains(q.X,q.Y,q.Z,p.Size.X/2,p.Size.Z/2) then
      h.hits[player]=cycle
      if not context.dodging(player,now) then
       humanoid:TakeDamage(config.hazardDamage)
       local velocity=if h.k==1 then Vector3.new(-13,4,0) elseif h.k==2 then Vector3.new(0,6,18) elseif h.k==6 then Vector3.new(0,32,0) else Vector3.zero
       r.AssemblyLinearVelocity+=velocity
      end
     end
    end
   end end
  end
 end
 return service
end
return H
