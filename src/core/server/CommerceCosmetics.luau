local Art=require(game.ReplicatedStorage.CC_Core.CommerceArt)
local M={};local ctx;local connections={}
function M.refresh(plr)
 local s,ch=ctx.sessions[plr],plr.Character;if not s or not ch then return end
 local old=ch:FindFirstChild("CC_CommerceCosmetics");if old then old:Destroy() end
 local f=Instance.new("Folder");f.Name="CC_CommerceCosmetics";f.Parent=ch
 local eq=s.data.commerce.equipped
 local earned=require(game.ReplicatedStorage.CC_Core.EarnedCosmetics)[s.data.expedition.earnedEquipped]
 if earned and not (s.data.expedition.earnedCosmetics or {})[s.data.expedition.earnedEquipped] then earned=nil end
 local torso=ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
 if eq.flag and not earned and torso then
  local m=Art.make("flag",f,torso.CFrame*CFrame.new(-0.3,-0.5,0.8),0.6)
  for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then if earned and p.Name~='Pole' then p.Color=earned.color end;p.Anchored=false;p.Massless=true;local w=Instance.new("WeldConstraint");w.Part0=torso;w.Part1=p;w.Parent=p end end
 end
 if earned then
  local id=s.data.expedition.earnedEquipped;local host=id=='summit_30' and ch:FindFirstChild('Head') or torso
  if host then local m=require(game.ReplicatedStorage.CC_Core.EarnedArt).make(id,f,host.CFrame*(id=='summit_30' and CFrame.new(0,.6,0) or CFrame.new(-.3,-.5,.8)))
   for _,p in m:GetDescendants() do if p:IsA('BasePart') then p.Anchored=false;p.Massless=true;local w=Instance.new('WeldConstraint');w.Part0=host;w.Part1=p;w.Parent=p end end
  end
 end
 local lamp=ch:FindFirstChild("Headlamp",true)
 if lamp and lamp:IsA("BasePart") then
  if not lamp:GetAttribute("CommerceOriginalColor") then lamp:SetAttribute("CommerceOriginalColor",lamp.Color) end
  lamp.Color=eq.lantern and Color3.fromRGB(255,190,52) or lamp:GetAttribute("CommerceOriginalColor")
  -- Only the casing changes. Light range, brightness, color and automatic activation stay untouched.
  if eq.lantern then
   local casing=Instance.new("Part");casing.Name="SunbeamCasing";casing.Size=Vector3.new(0.48,0.36,0.12);casing.Color=Color3.fromRGB(91,62,151);casing.CFrame=lamp.CFrame*CFrame.new(0,0,0.14);casing.Massless=true;casing.CanCollide=false;casing.CanTouch=false;casing.CanQuery=false;casing.Parent=f
   local w=Instance.new("WeldConstraint");w.Part0=lamp;w.Part1=casing;w.Parent=casing
  end
 end
 local root=ch:FindFirstChild("HumanoidRootPart")
 if eq.trail and root then
  local a=Instance.new("Attachment");a.Name="TrailAnchor";a.Position=Vector3.new(0,-1,0.7);a.Parent=f
  -- Attachments need a part ancestor; a welded inert carrier keeps cleanup within our own subtree.
  local carrier=Instance.new("Part");carrier.Name="TrailCarrier";carrier.Size=Vector3.new(0.1,0.1,0.1);carrier.Transparency=1;carrier.CFrame=root.CFrame;carrier.Massless=true;carrier.CanCollide=false;carrier.CanTouch=false;carrier.CanQuery=false;carrier.Parent=f;a.Parent=carrier
  local w=Instance.new("WeldConstraint");w.Part0=root;w.Part1=carrier;w.Parent=carrier
  local p=Instance.new("ParticleEmitter");p.Name="SunbeamSparkles";p.Texture="rbxasset://textures/particles/sparkles_main.dds";p.Rate=5;p.Lifetime=NumberRange.new(0.45,0.7);p.Speed=NumberRange.new(0,0.4);p.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.22),NumberSequenceKeypoint.new(1,0)});p.Color=ColorSequence.new(Color3.fromRGB(255,218,91),Color3.fromRGB(96,221,235));p.LightEmission=0.6;p.Enabled=not s.data.settings.reducedMotion;p.Parent=a
 end
end
function M.home(room,data)
 local old=room.model:FindFirstChild("CommerceDecor");if old then old:Destroy() end
 local f=Instance.new("Folder");f.Name="CommerceDecor";f.Parent=room.model
 if data.commerce.equipped.banner then Art.make("banner",f,CFrame.new(room.center+Vector3.new(-6,0,-23)),1.3) end
 if data.home.decorEquipped.lamp then
  for _,x in ipairs({-9,9}) do Art.make("lamp",f,CFrame.new(room.center+Vector3.new(x,0,-19)),1.2) end
 end
end
function M.init(c) ctx=c end
function M.onCharacter(plr,ch)
 M.onLeave(plr)
 connections[plr]={
  ch.ChildAdded:Connect(function(v) if v.Name=="CC_Gear" then task.defer(function() if plr.Character==ch then M.refresh(plr) end end) end end),
  plr:GetAttributeChangedSignal("CC_ReducedMotion"):Connect(function() M.refresh(plr) end),
 }
 task.delay(1,function() if plr.Character==ch then M.refresh(plr) end end)
end
function M.onLoaded(plr) M.refresh(plr) end
function M.onLeave(plr) for _,c in ipairs(connections[plr] or {}) do c:Disconnect() end;connections[plr]=nil end
return M
