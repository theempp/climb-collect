-- Step 2 only. Run in the separately saved review place. No gameplay scripts.
local root=workspace.MountainEmpire_Step1
assert(not root:FindFirstChild("EnchantedAlpineLodges"),"Lodges already exist")
local folder=Instance.new("Folder")
folder.Name="EnchantedAlpineLodges"
folder.Parent=root
local V=Vector3.new
local C=Color3.fromRGB
local timber=C(91,57,37)
local cedar=C(156,109,66)
local stone=C(133,144,143)
local dark=C(32,55,57)
local roofColor=C(39,77,78)
local brass=C(185,146,78)
local glass=C(163,221,221)
local glow=C(138,237,217)
local centers={-658,-470,-282,-94,94,282,470,658}
for i,cx in centers do
 local m=Instance.new("Model")
 m.Name=string.format("Lodge_%02d",i)
 m:SetAttribute("PlotIndex",i)
 m:SetAttribute("FootprintWidth",35)
 m:SetAttribute("FootprintDepth",30)
 m:SetAttribute("Facing","NegativeZ")
 m:SetAttribute("DecorativeOnly",true)
 local function part(name,size,pos,mat,color,collide,rot)
  local p=Instance.new("Part")
  p.Name=name p.Size=size p.CFrame=CFrame.new(V(cx,0,200)+pos)*(rot or CFrame.identity)
  p.Material=mat p.Color=color p.Anchored=true p.CanCollide=collide==true
  p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=m return p
 end
 local function beam(name,a,b,width,depth,mat,color)
  local p=part(name,V(width,(b-a).Magnitude,depth),(a+b)/2,mat,color,false)
  local up=(b-a).Unit
  local right=up:Cross(V(0,0,1)).Unit
  p.CFrame=CFrame.fromMatrix(V(cx,0,200)+(a+b)/2,right,up,V(0,0,1))
  return p
 end
 -- Walkable foundation and open recessed entrance.
 part("StoneFoundation",V(30,1,22),V(0,.5,3),Enum.Material.Slate,stone,true)
 part("PorchDeck",V(30,1,5),V(0,.5,-10.5),Enum.Material.WoodPlanks,cedar,true)
 for j=1,3 do
  part("EntryStep_"..j,V(8,j/3,.65),V(0,j/6,-15+(j-.5)*.65),Enum.Material.Slate,stone,true)
 end
 -- Rear and side walls are split around actual glazed openings.
 part("RearTimberWall",V(30,11,1),V(0,6.5,13.5),Enum.Material.WoodPlanks,cedar,true)
 for _,side in {-1,1} do
  part("SideStoneBase",V(1,3,22),V(side*14.5,2.5,3),Enum.Material.Cobblestone,stone,true)
  part("SideUpperBand",V(1,2,22),V(side*14.5,11,3),Enum.Material.WoodPlanks,cedar,true)
  for _,z in {-7.5,3,13.5} do
   part("SideTimberPier",V(1.2,7,1.2),V(side*14.5,7.5,z),Enum.Material.Wood,timber,true)
  end
  for _,z in {-2.25,8.25} do
   local g=part("SideGlazing",V(.3,6,9.3),V(side*14.5,7,z),Enum.Material.Glass,glass,true)
   g.Transparency=.3 g.Reflectance=.08
   part("SideMullion",V(.55,6.5,.28),V(side*14.72,7,z),Enum.Material.Metal,dark,false)
   part("SideWindowSill",V(1.4,.3,9.5),V(side*14.5,4,z),Enum.Material.Wood,timber,false)
  end
  part("FrontStonePlinth",V(11.8,2.3,1),V(side*9,2.15,-7.5),Enum.Material.Cobblestone,stone,true)
  local g=part("FrontGlazing",V(10.6,7.3,.32),V(side*9,6.95,-7.7),Enum.Material.Glass,glass,true)
  g.Transparency=.28 g.Reflectance=.08
  for _,x in {side*3.3,side*14.7} do
   part("FrontTimberPost",V(.8,11,1.1),V(x,6.5,-7.7),Enum.Material.Wood,timber,true)
  end
  for _,x in {side*7.1,side*10.9} do
   part("FrontWindowMullion",V(.22,7.5,.5),V(x,7,-7.95),Enum.Material.Metal,dark,false)
  end
  part("WindowTransom",V(10.8,.22,.55),V(side*9,8.7,-7.95),Enum.Material.Metal,dark,false)
  part("WindowSill",V(11.8,.35,1.3),V(side*9,3.3,-7.7),Enum.Material.Wood,timber,false)
  -- Stone feet, porch columns and braced beam connections.
  part("PorchPier",V(2,2,2),V(side*13,1,-12),Enum.Material.Cobblestone,stone,true)
  part("PorchColumn",V(.85,9.7,.85),V(side*13,6.85,-12),Enum.Material.Wood,timber,true)
  beam("PorchKneeBrace",V(side*13,8.2,-12),V(side*10.8,10.8,-12),.5,.65,Enum.Material.Wood,timber)
  part("ColumnCollar",V(1.05,.35,1.05),V(side*13,3,-12),Enum.Material.Metal,brass,false)
  -- Restrained lanterns, no particles or dynamic lights.
  part("LanternBackplate",V(.8,2.2,.18),V(side*4.4,6.5,-8.4),Enum.Material.Metal,dark,false)
  local lamp=part("EnchantedLantern",V(.48,1.1,.5),V(side*4.4,6.5,-8.8),Enum.Material.Neon,glow,false)
  for _,y in {5.85,7.15} do
   part("LanternCap",V(.8,.15,.75),V(side*4.4,y,-8.8),Enum.Material.Metal,brass,false)
  end
 end
 part("EntryLintel",V(7.2,1.2,1.1),V(0,10.6,-7.7),Enum.Material.Wood,timber,true)
 part("FrontEaveBeam",V(30.8,.85,1.1),V(0,11.5,-12),Enum.Material.Wood,timber,false)
 part("RearEaveBeam",V(30.8,.85,1.1),V(0,11.5,13.6),Enum.Material.Wood,timber,false)
 -- Transparent gable panels, peaked timber trusses, layered standing-seam roof.
 for _,z in {-7.5,13.5} do
  for _,side in {-1,1} do
   local g=Instance.new("WedgePart")
   g.Name="GableGlass" g.Size=V(.32,9.7,14.5)
   g.CFrame=CFrame.new(cx+side*7.25,16.85,200+z)*CFrame.Angles(0,-side*math.pi/2,0)
   g.Material=Enum.Material.Glass g.Color=glass g.Transparency=.3 g.Anchored=true g.CanCollide=true g.CanTouch=false g.Parent=m
   beam("GableRafter",V(side*15,11.6,z-.3),V(0,22,z-.3),.7,.65,Enum.Material.Wood,timber)
   beam("GableStrut",V(side*8.5,11.8,z-.35),V(0,18.5,z-.35),.4,.45,Enum.Material.Wood,timber)
  end
  part("GableKingpost",V(.65,10.4,.65),V(0,16.8,z-.35),Enum.Material.Wood,timber,false)
  part("GableTie",V(30,.7,.8),V(0,11.7,z-.3),Enum.Material.Wood,timber,false)
 end
 local angle=math.atan2(10.5,16.8)
 local length=math.sqrt(16.8^2+10.5^2)
 for _,side in {-1,1} do
  local rot=CFrame.Angles(0,0,-side*angle)
  part("RoofUnderlay",V(length,.6,28.5),V(side*8.4,17.25,.25),Enum.Material.Wood,timber,true,rot)
  for course=0,5 do
   local t=(course+.5)/6
   part("RoofCourse_"..course,V(length/6+.13,.25,28.4),V(side*(16.8*(1-t)),12+10.5*t+.36,.25),Enum.Material.Slate,roofColor,false,rot)
  end
  for _,z in {-13.65,-7,0,7,14.15} do
   part("RoofStandingSeam",V(length,.18,.11),V(side*8.4,17.85,z),Enum.Material.Metal,brass,false,rot)
  end
  for _,z in {-14.15,14.4} do
   beam("DeepRoofFascia",V(side*16.8,12,z),V(0,22.5,z),.8,.5,Enum.Material.Wood,timber)
   beam("FasciaBrassInlay",V(side*16.8,12.25,z-.28),V(0,22.75,z-.28),.12,.1,Enum.Material.Metal,brass)
  end
  part("EaveRail",V(.5,.5,28.8),V(side*16.8,12,.25),Enum.Material.Wood,timber,false)
 end
 part("RidgeCap",V(.65,.5,29),V(0,22.75,0),Enum.Material.Metal,brass,false)
 -- Faceted crest above the covered entrance.
 local gem=part("AlpineCrest",V(1.15,1.15,.3),V(0,17.2,-14.55),Enum.Material.Neon,glow,false,CFrame.Angles(0,0,math.pi/4))
 for _,side in {-1,1} do
  beam("CrestMount",V(0,16,-14.4),V(side*1.5,17.2,-14.4),.16,.18,Enum.Material.Metal,brass)
  beam("CrestMount",V(side*1.5,17.2,-14.4),V(0,18.4,-14.4),.16,.18,Enum.Material.Metal,brass)
 end
 part("CrestHanger",V(.16,4.1,.16),V(0,20.45,-14.4),Enum.Material.Metal,brass,false)
 -- Compact masonry chimney and cap, with no smoke emitter.
 part("Chimney",V(2.7,10,2.7),V(9,16,8),Enum.Material.Cobblestone,stone,true)
 part("ChimneyCrown",V(3.3,.5,3.3),V(9,21.2,8),Enum.Material.Slate,dark,false)
 part("ChimneyTop",V(2.1,.15,2.1),V(9,21.5,8),Enum.Material.SmoothPlastic,dark,false)
 for _,x in {-14,14} do
  part("PorchSideRail",V(.4,.5,4.7),V(x,3.7,-10.4),Enum.Material.Wood,timber,false)
 end
 -- Non-interactive plot number, attached to the entry beam.
 local plaque=part("EstateNumber",V(2.4,.85,.15),V(0,10.6,-8.35),Enum.Material.Metal,dark,false)
 local gui=Instance.new("SurfaceGui") gui.Name="DecorativeNumber" gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(240,85) gui.Parent=plaque
 local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Text=string.format("%02d",i) label.TextColor3=brass label.TextScaled=true label.Font=Enum.Font.GothamMedium label.Parent=gui
 m.PrimaryPart=m.StoneFoundation
 m.Parent=folder
 local plot=root.SanctuaryPlots:FindFirstChild(string.format("Plot_%02d",i))
 for _,p in plot:GetChildren() do
  if string.find(p.Name,"LodgeFootprint") then p.Transparency=1 p.CanCollide=false p.CanQuery=false end
 end
 task.wait()
end
workspace:SetAttribute("ReviewStage","Step2_EightLodges_VisualReview")
return {lodges=#folder:GetChildren(),descendants=#folder:GetDescendants()}

