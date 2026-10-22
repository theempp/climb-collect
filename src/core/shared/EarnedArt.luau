local Catalog=require(script.Parent.EarnedCosmetics);local A={}
function A.make(id,parent,cf)
 local item=Catalog[id];if not item then return end
 if id~='summit_5' and id~='summit_30' then
  local m=require(script.Parent.CommerceArt).make('flag',parent,cf,.6)
  for _,p in m:GetDescendants() do if p:IsA('BasePart') and p.Name=='Banner' then p.Color=item.color end end
  if id=='summit_15' then for _,p in m:GetDescendants() do if p:IsA('BasePart') and p.Name=='Hem' then p.Color=Color3.fromRGB(85,240,211) end end end
  return m
 end
 local m=Instance.new('Model');m.Name=item.name
 local function p(name,size,pos,color,shape)
  local x=Instance.new('Part');x.Name=name;x.Size=size;x.CFrame=CFrame.new(pos);x.Color=color or item.color;x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false;x.Material=Enum.Material.SmoothPlastic;if shape then x.Shape=shape end;x.Parent=m;return x
 end
 if id=='summit_30' then
  for i=0,7 do local theta=i*math.pi/4;local pos=Vector3.new(math.cos(theta)*.8,.2,math.sin(theta)*.8)
   p('CrownBand',Vector3.new(.75,.3,.18),pos):SetAttribute('Cosmetic',true);m:GetChildren()[#m:GetChildren()].CFrame=CFrame.new(pos)*CFrame.Angles(0,-theta+math.pi/2,0)
   p('CrownTip',Vector3.new(.18,.6,.18),pos+Vector3.yAxis*.35);p('SummitGem',Vector3.one*.25,pos+Vector3.yAxis*.7,Color3.fromRGB(71,201,216),Enum.PartType.Ball)
  end
 else
  p('SkyCrest',Vector3.new(1.6,1.8,.25),Vector3.new(0,0,0),item.color,Enum.PartType.Ball)
  for _,side in {-1,1} do local w=Instance.new('WedgePart');w.Name='MountainRelief';w.Size=Vector3.new(.1,1,.55);w.CFrame=CFrame.new(side*.275,.1,-.2)*CFrame.Angles(0,side*math.pi/2,0);w.Color=Color3.fromRGB(255,241,197);w.Anchored=true;w.CanCollide=false;w.CanQuery=false;w.CanTouch=false;w.Parent=m end
 end
 m.WorldPivot=CFrame.identity;m:PivotTo(cf);m.Parent=parent;return m
end
return A
