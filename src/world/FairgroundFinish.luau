-- Presentation-only finish pass. No terrain writes, route edits or service-anchor changes.
local F={}
function F.build()
 local w=workspace.World;assert(w:FindFirstChild('Fairground'),'review fairground required')
 if w:FindFirstChild('FairgroundFinish') then return end
 local root=Instance.new('Model');root.Name='FairgroundFinish';root.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local base=CFrame.new(0,48,2040)
 local cream=Color3.fromRGB(255,239,203);local ink=Color3.fromRGB(30,52,61);local gold=Color3.fromRGB(255,188,48)
 local teal=Color3.fromRGB(19,160,162);local orange=Color3.fromRGB(235,113,48);local purple=Color3.fromRGB(132,78,201)
 local function p(name,size,cf,color,shape)
  local v=Instance.new('Part');v.Name=name;v.Size=size;v.CFrame=base*cf;v.Color=color;v.Material=Enum.Material.SmoothPlastic;v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;if shape then v.Shape=shape end;v.Parent=root;return v
 end
 local function beam(name,a,b,width,color)
  return p(name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color)
 end
 local function sign(at,text,width,height,color)
  local plate=p('EnamelSign',Vector3.new(width,height,.25),at,color)
  local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=35;g.Parent=plate
  local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=UDim2.fromScale(.94,.9);t.Position=UDim2.fromScale(.03,.05);t.Text=text;t.Font=Enum.Font.FredokaOne;t.TextScaled=true;t.TextColor3=cream;t.Parent=g
 end
 local archive=Instance.new('Folder');archive.Name='BeforePolishCanopies';archive.Parent=game.ServerStorage
 for _,v in w.Fairground:GetDescendants() do if v.Name=='StripedCanopy' then v.Parent=archive end end
 for _,spec in {{54,30,30,gold},{58,-47,42,purple},{-30,76,28,orange},{-56,27,30,purple}} do
  local x,z,width,color=table.unpack(spec)
  for i=1,10 do
   local stripe=i%2==0 and cream or color;local sx=x-width/2+(i-.5)*width/10
   for _,side in {-1,1} do
    p('PitchedCanvas',Vector3.new(width/10+.06,.28,14.8),CFrame.new(sx,19.5,z+side*6.65)*CFrame.Angles(side*math.rad(26),0,0),stripe)
    p('ScallopedValance',Vector3.new(width/10,2,1),CFrame.new(sx,15.6,z+side*13.3),stripe,Enum.PartType.Ball)
   end
  end
  p('RidgeCap',Vector3.new(width+1,.6,.7),CFrame.new(x,22.8,z),gold)
  for _,side in {-1,1} do
   local px=x+side*width/2
   beam('KneeBrace',Vector3.new(px,10,z+10),Vector3.new(px-side*5,15,z+10),.55,ink)
   p('PostCollar',Vector3.new(1.8,.6,1.8),CFrame.new(px,12,z+10),cream)
   p('HangingLantern',Vector3.new(1.6,2.5,1.6),CFrame.new(px,11,z+10),ink)
   p('WarmLanternGlass',Vector3.new(1.3,1.7,1.3),CFrame.new(px,11,z+10),gold)
   beam('LanternHanger',Vector3.new(px,12.5,z+10),Vector3.new(px,15,z+10),.15,ink)
  end
  for i=-1,1 do p('CounterPanel',Vector3.new(width/3-1,3.5,.4),CFrame.new(x+i*width/3,2.8,z+8),color) end
 end
 -- Original north-star medallion, flush with the open gathering court.
 for i=0,7 do
  local angle=i*math.pi/4;local long=i%2==0 and 13 or 8
  for _,side in {-1,1} do
   local wedge=Instance.new('WedgePart');wedge.Name='CompassRay';wedge.Size=Vector3.new(.12,long,3.2);wedge.CFrame=base*CFrame.new(0,1.04,4)*CFrame.Angles(0,angle,math.pi/2)*CFrame.new(0,long/2,side*1.6)*CFrame.Angles(0,side<0 and math.pi or 0,0);wedge.Color=side>0 and teal or gold;wedge.Anchored=true;wedge.CanCollide=false;wedge.CanTouch=false;wedge.CanQuery=false;wedge.Parent=root
  end
 end
 p('CompassBoss',Vector3.new(.15,4,4),CFrame.new(0,1.1,4)*CFrame.Angles(0,0,math.pi/2),cream,Enum.PartType.Cylinder)
 -- Lush contained beds frame corners without filling the walking lanes.
 for _,bed in {{-84,65},{85,43},{-84,-62},{84,-76}} do
  local x,z=table.unpack(bed)
  p('PlanterRim',Vector3.new(13,2,7),CFrame.new(x,1.5,z),ink)
  p('PlanterSoil',Vector3.new(12.2,.3,6.2),CFrame.new(x,2.6,z),Color3.fromRGB(80,74,52))
  for i=1,5 do
   local px=x-6+i*2;local h=3+(i%3)
   p('LeafCrown',Vector3.new(4,h,3.8),CFrame.new(px,3+h*.3,z)*CFrame.Angles(0,i*.8,.2),i%2==0 and Color3.fromRGB(42,148,112) or Color3.fromRGB(62,183,119),Enum.PartType.Ball)
   beam('FlowerStem',Vector3.new(px,2.5,z+2),Vector3.new(px,5+i%2,z+2),.14,teal)
   for j=0,4 do p('FlowerPetal',Vector3.new(1,.35,1.5),CFrame.new(px,5+i%2,z+2)*CFrame.Angles(0,j*math.pi*2/5,0)*CFrame.new(0,0,.6),i%2==0 and gold or cream,Enum.PartType.Ball) end
   p('FlowerHeart',Vector3.one*.45,CFrame.new(px,5.3+i%2,z+2),orange,Enum.PartType.Ball)
  end
 end
 -- Practice side/back rock facets retain every actual climb face and stair clearance.
 for _,wall in w.TrainingYard:GetDescendants() do if wall:IsA('BasePart') and wall.Name=='PracticeWall' then
  local cf=base:ToObjectSpace(wall.CFrame)
  for i=1,3 do
   local shard=Instance.new('WedgePart');shard.Name='PracticeRockFacet';shard.Size=Vector3.new(3,wall.Size.Y*(.65+i*.1),6);shard.CFrame=base*cf*CFrame.new(-wall.Size.X/2-1,(i-2)*.6,(i-2)*2)*CFrame.Angles(0,i*.18,0);shard.Color=({Color3.fromRGB(54,100,112),Color3.fromRGB(73,125,133),Color3.fromRGB(91,143,144)})[i];shard.Material=Enum.Material.Slate;shard.Anchored=true;shard.CanCollide=false;shard.CanTouch=false;shard.CanQuery=false;shard.Parent=root
  end
  for _,side in {-1,1} do
   p('PracticeEdgeStripe',Vector3.new(.25,wall.Size.Y,.15),cf*CFrame.new(side*(wall.Size.X/2-.4),0,wall.Size.Z/2+.1),gold)
  end
 end end
 sign(CFrame.new(-70,4,-24),'CLIP IN • CLIMB • RING THE BELL',28,2.2,teal)
 root.Parent=w;return #root:GetDescendants()
end
return F
