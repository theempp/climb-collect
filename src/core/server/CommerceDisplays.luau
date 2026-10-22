local Art=require(game.ReplicatedStorage.CC_Core.CommerceArt)
local M={}
local connections={} 
function M.build()
 local world=workspace:FindFirstChild("World");assert(world,"world missing")
 if world:FindFirstChild("CommerceDisplays") then return world.CommerceDisplays end
 local f=Instance.new("Folder");f.Name="CommerceDisplays"
 local anchors=world:FindFirstChild("Fairground") and require(script.Parent.LobbyAnchors).resolve(world)
 local market=not anchors and world.Regions.Foothold.Districts.ProvisionsMarket
 local stalls={};for _,v in ipairs(market and market:GetChildren() or {}) do if v.Name=="MarketStall" and v:IsA("Model") then table.insert(stalls,v) end end
 table.sort(stalls,function(a,b) return a:GetPivot().Position.Z<b:GetPivot().Position.Z end)
 assert(anchors or #stalls==4,"market layout changed")
 local function display(id,at,key)
  local m=Instance.new("Model");m.Name=key;m:SetAttribute("CommerceOffer",id);m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  local base=Instance.new("Part");base.Name="Plinth";base.Size=Vector3.new(3.7,1,3.2);base.CFrame=CFrame.new(at);base.Color=Color3.fromRGB(88,49,125);base.Material=Enum.Material.Slate;base.Anchored=true;base.CanCollide=false;base.CanTouch=false;base.Parent=m
  local top=base:Clone();top.Name="GoldRim";top.Size=Vector3.new(3.9,0.13,3.4);top.CFrame=base.CFrame*CFrame.new(0,0.55,0);top.Color=Color3.fromRGB(255,204,95);top.Parent=m
  Art.make(id=="next" and "upgrade0" or id,m,base.CFrame*CFrame.new(0,0.65,0),0.95)
  local pr=Instance.new("ProximityPrompt");pr.Name="CommercePrompt";pr.ActionText="View offer";pr.ObjectText="Foothold Exchange";pr.MaxActivationDistance=10;pr.RequiresLineOfSight=false;pr.Parent=base
  m.PrimaryPart=base;m.Parent=f
 end
 if anchors then
  for _,row in ipairs({{"bundle","Bundle"},{"flag","Flag"},{"trail","Trail"},{"next","Next"},{"coins100","Coins"}}) do display(row[1],anchors["Exchange_"..row[2]].Position-Vector3.new(0,1,0),row[2]) end
  f.Parent=world;return f
 end
 for i,id in ipairs({"bundle","flag","trail"}) do
  local cf=stalls[i]:GetPivot();local at=cf.Position+cf.LookVector*7
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={market}
  local hit=workspace:Raycast(at+Vector3.new(0,20,0),Vector3.new(0,-60,0),params)
  display(id,Vector3.new(at.X,hit and hit.Position.Y+0.5 or 49,at.Z),"Market_"..i)
 end
 local fire=world.Regions.Foothold.Core.Campfire:GetPivot().Position
 for i,id in ipairs({"next","coins100"}) do
  local at=fire+Vector3.new(i==1 and -9 or 9,0,8)
  local hit=workspace:Raycast(at+Vector3.new(0,20,0),Vector3.new(0,-60,0))
  display(id,Vector3.new(at.X,hit and hit.Position.Y+0.5 or fire.Y,at.Z),"Bank_"..i)
 end
 f.Parent=world;return f
end
function M.init(ctx)
 for _,c in connections do c:Disconnect() end;table.clear(connections)
 local f=M.build()
 for _,m in ipairs(f:GetChildren()) do
  local pr=m.PrimaryPart:FindFirstChild("CommercePrompt")
  table.insert(connections,pr.Triggered:Connect(function(plr)
   local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart");local s=ctx.sessions[plr]
   if not s or not root or (root.Position-m.PrimaryPart.Position).Magnitude>13 then return end
   local id=m:GetAttribute("CommerceOffer");if id=="next" then id="upgrade"..math.min(s.data.commerce.tier,5) end
   ctx.fx(plr,{kind="commerceOpen",offerId=id})
  end))
 end
end
return M
