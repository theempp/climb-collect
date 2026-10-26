-- Cosmetic server models replicate to every player; they never grant ownership.
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local A=require(game.ServerStorage.MountainWorld.Art)
local V={}
function V.new(world,send)
 local folder=Instance.new('Folder');folder.Name='RaidPresentation';folder.Parent=world
 local carries,tools,shells={},{},{}
 local function clear(player)
  if carries[player] then carries[player]:Destroy();carries[player]=nil end
  if tools[player] then tools[player]:Destroy();tools[player]=nil end
  if player.Character then player.Character:SetAttribute('CarryingCreature',false) end
 end
 local function creature(player,species,position)
  if carries[player] then carries[player]:Destroy() end
  local entry=table.clone(C.byId[species])
  -- Portable adults omit boss-only orbit/crest proportions. Existing boss art is untouched.
  if entry.rarity=='Legendary' then entry.rarity='Mythic';entry.variant=1 end
  local model=A.creature(folder,entry,position,.55,1)
  model.Name='Carried_'..player.UserId;model:SetAttribute('CarryOwner',player.UserId)
  model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA('BasePart') then
    part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
    if part.Name=='Wing' then
     local localCF=model.PrimaryPart.CFrame:ToObjectSpace(part.CFrame)
     part.CFrame=model.PrimaryPart.CFrame*CFrame.new(localCF.Position.X*.5,localCF.Position.Y,localCF.Position.Z)*localCF.Rotation*CFrame.Angles(0,0,if localCF.Position.X>0 then .8 else -.8)
     part:SetAttribute('RestLocal',model.PrimaryPart.CFrame:ToObjectSpace(part.CFrame))
    end
   end
  end
  carries[player]=model;return model
 end
 local service={}
 function service.shell(egg)
  local shell=A.part(folder,'Egg_'..egg.id,Vector3.new(3,3.9,3),CFrame.new(egg.position+Vector3.new(0,2.4,0)),Color3.fromRGB(247,229,191),Enum.Material.SmoothPlastic,Enum.PartType.Ball,false)
  shell:SetAttribute('RaidEgg',egg.id);shells[egg.id]=shell
 end
 function service.show(player,data)
  local character=player.Character;local rr=character and character:FindFirstChild('HumanoidRootPart')
  if data.kind=='lost' then
   clear(player)
   local shell=shells[data.eggId]
   if shell then shell.Transparency=0;shell:SetAttribute('Hits',0);for _,v in ipairs(shell:GetChildren()) do if v:IsA('BasePart') then v:Destroy() end end end
   send(player,'toast','Unsecured '..C.byId[data.species].name..' lost. Try another egg.');return
  end
  if data.kind=='strike' then
   if character then character:SetAttribute('PickaxeStrikeAt',workspace:GetServerTimeNow()) end
   if not tools[player] then
    local m=Instance.new('Model');m.Name='Pickaxe_'..player.UserId
    m.PrimaryPart=A.part(m,'Handle',Vector3.new(.25,2.6,.25),CFrame.new(),Color3.fromRGB(118,78,48),Enum.Material.Wood,nil,false)
    A.part(m,'SteelHead',Vector3.new(2.3,.35,.48),CFrame.new(0,1,0),Color3.fromRGB(187,215,219),Enum.Material.Metal,nil,false)
    m.Parent=folder;tools[player]=m
   end
   local shell=shells[data.egg.id]
   if shell then
    shell:SetAttribute('Hits',data.run.hits);shell:SetAttribute('RequiredHits',data.hitsRequired)
    local crack=A.part(shell,'Crack',Vector3.new(.08,1.7,.08),shell.CFrame*CFrame.new((data.run.hits-2)*.3,.1,-1.47)*CFrame.Angles(0,0,.35*(data.run.hits%2*2-1)),Color3.fromRGB(107,83,65),Enum.Material.Slate,nil,false)
    if data.run.phase=='revealed' then
     shell.Transparency=.8
     task.delay(18,function() if shell.Parent then shell.Transparency=0;shell:SetAttribute('Hits',0);for _,v in ipairs(shell:GetChildren()) do if v:IsA('BasePart') then v:Destroy() end end end end)
    end
   end
   if data.run.phase=='revealed' then
    creature(player,data.run.species,data.egg.position+Vector3.new(0,1,0))
    send(player,'toast',C.byId[data.run.species].name..' revealed — pick it up and escape!')
   end
  elseif data.kind=='reveal' then creature(player,data.run.species,data.egg.position)
  elseif data.kind=='carry' then
   if character then character:SetAttribute('CarryingCreature',true) end
   if carries[player] then carries[player]:SetAttribute('InArms',true) end
   if tools[player] then tools[player]:Destroy();tools[player]=nil end
  elseif data.kind=='securing' then send(player,'toast','Securing your creature… You are protected while saving.')
  elseif data.kind=='safe' then
   if carries[player] then carries[player]:SetAttribute('Secured',true) end
   send(player,'toast','Safe! '..C.byId[data.species].name..' is yours. Carry it home.')
  end
 end
 function service.tick()
  for player,model in pairs(carries) do
   local rr=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
   if rr and model:GetAttribute('InArms') then model:PivotTo(rr.CFrame*CFrame.new(0,.15,-1.55)*CFrame.Angles(0,math.pi/2,0)) end
  end
  for player,model in pairs(tools) do
   local c=player.Character;local hand=c and (c:FindFirstChild('RightHand') or c:FindFirstChild('Right Arm'))
   if hand then
    local elapsed=workspace:GetServerTimeNow()-(c:GetAttribute('PickaxeStrikeAt') or 0)
    model:PivotTo(hand.CFrame*CFrame.new(0,-.4,-.6)*CFrame.Angles(-.4-math.sin(math.clamp(elapsed/.35,0,1)*math.pi)*1.2,0,0))
   end
  end
 end
 service.clear=clear
 return service
end
return V
