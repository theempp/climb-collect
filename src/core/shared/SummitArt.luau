-- Original faceted alpine rescue aircraft. All geometry is local presentation only.
local A={}
function A.helicopter(parent)
 local m=Instance.new('Model');m.Name='SummitRescue'
 local cream=Color3.fromRGB(255,240,203);local teal=Color3.fromRGB(13,143,153)
 local ink=Color3.fromRGB(25,43,59);local gold=Color3.fromRGB(255,188,47)
 local glass=Color3.fromRGB(38,94,123);local red=Color3.fromRGB(243,85,62)
 local function p(name,size,cf,color,shape,owner)
  local v=Instance.new('Part');v.Name=name;v.Size=size;v.CFrame=cf;v.Color=color;v.Material=Enum.Material.SmoothPlastic
  v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth
  if shape then v.Shape=shape end;v.Parent=owner or m;return v
 end
 local function rod(name,a,b,width,color,owner)
  return p(name,Vector3.new(width,width,(a-b).Magnitude),CFrame.lookAt((a+b)/2,b),color,nil,owner)
 end
 -- Triangulated skins produce a tapered silhouette, instead of overlapping ellipsoids.
 local function tri(name,a,b,c,color)
  local ab,ac,bc=b-a,c-a,c-b
  if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then a,c=c,a
  elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b
  local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=bc:Cross(right).Unit
  local height=math.abs(ab:Dot(up))
  for _,v in {{a,b,right,up,back,math.abs(ab:Dot(back))},{a,c,-right,up,-back,math.abs(ac:Dot(back))}} do
   if v[6]>.01 and height>.01 then
    local w=Instance.new('WedgePart');w.Name=name;w.Size=Vector3.new(.08,height,v[6]);w.CFrame=CFrame.fromMatrix((v[1]+v[2])/2,v[3],v[4],v[5]);w.Color=color;w.Material=Enum.Material.SmoothPlastic;w.Anchored=true;w.CanCollide=false;w.CanTouch=false;w.CanQuery=false;w.Parent=m
   end
  end
 end
 -- Octagonal sections, nose at negative Z; starboard doorway left deliberately open.
 local rings={{-8,2.5,1.5,-.4},{-5,4.2,3.2,0},{-1,4.5,3.5,0},{5,4.1,3.1,.1},{8,2.3,2.2,.6}}
 local verts={}
 for i,r in rings do
  verts[i]={};for j=0,7 do local a=j*math.pi/4;verts[i][j+1]=Vector3.new(math.cos(a)*r[2],math.sin(a)*r[3]+r[4],r[1]) end
 end
 for i=1,#rings-1 do for j=1,8 do
  local k=j%8+1
  if not (i==3 and (j==1 or j==8)) then
   local color=(j>=5 and j<=8) and cream or teal
   if i<=2 and (j==1 or j==2 or j==3 or j==4) then color=glass end
   tri('FuselagePanel',verts[i][j],verts[i+1][j],verts[i+1][k],color)
   tri('FuselagePanel',verts[i][j],verts[i+1][k],verts[i][k],color)
  end
 end end
 for j=1,8 do local k=j%8+1;tri('NoseCap',Vector3.new(0,-.4,-8.5),verts[1][j],verts[1][k],cream);tri('RearCap',Vector3.new(0,.6,8.2),verts[5][k],verts[5][j],teal) end
 local pivot=p('AircraftOrigin',Vector3.one*.1,CFrame.new(),ink);pivot.Transparency=1;m.PrimaryPart=pivot
 -- Windscreen pillars, brow and restrained highlights.
 for j=1,5 do rod('CockpitFrame',verts[1][j],verts[2][j],.17,cream);rod('CabinFrame',verts[2][j],verts[3][j],.15,teal) end
 for j=1,4 do rod('WindscreenBrow',verts[2][j],verts[2][j+1],.18,cream) end
 rod('GlassGlint',Vector3.new(1.9,2.3,-6.2),Vector3.new(2.7,2.4,-4),.09,Color3.fromRGB(147,227,231))
 p('NoseSearchlight',Vector3.new(1.4,1.1,.3),CFrame.new(0,-.6,-8.6),gold,Enum.PartType.Ball)
 p('CabinFloor',Vector3.new(7.7,.35,7),CFrame.new(0,-2.5,2),ink)
 p('BenchCushion',Vector3.new(2,1,4.7),CFrame.new(-2,-1.8,2),gold)
 p('BenchBack',Vector3.new(.5,2.7,4.7),CFrame.new(-3,-.8,2),ink)
 for _,z in {-.5,4.7} do rod('DoorFrame',Vector3.new(4.3,-2.5,z),Vector3.new(4.3,2.7,z),.22,cream) end
 rod('DoorRail',Vector3.new(4.4,2.8,-.8),Vector3.new(4.4,2.8,8),.18,ink)
 local door=Instance.new('Model');door.Name='Door';door.Parent=m
 p('SlidingDoorLower',Vector3.new(.22,2.4,4.9),CFrame.new(4.45,-1.2,2.1),teal,nil,door)
 p('SlidingDoorWindow',Vector3.new(.24,2.4,4.9),CFrame.new(4.45,1.2,2.1),glass,nil,door)
 for _,z in {-.4,4.6} do rod('DoorEdge',Vector3.new(4.6,-2.5,z),Vector3.new(4.6,2.5,z),.15,cream,door) end
 p('DoorHandle',Vector3.new(.3,.22,1.1),CFrame.new(4.7,-.2,3.6),gold,nil,door);door.WorldPivot=CFrame.new()
 -- Engine nacelle, air intake and exhaust pair.
 p('EnginePod',Vector3.new(4.5,2.6,7),CFrame.new(0,3.5,1.4),teal,Enum.PartType.Ball)
 p('Intake',Vector3.new(3.1,1.1,.3),CFrame.new(0,3.8,-1.6),ink)
 for i=-3,3 do p('IntakeGrille',Vector3.new(.13,.95,.15),CFrame.new(i*.4,3.8,-1.8),cream) end
 for _,x in {-1.6,1.6} do p('Exhaust',Vector3.new(2,1.15,1.15),CFrame.new(x,3.6,5)*CFrame.Angles(0,math.pi/2,0),ink,Enum.PartType.Cylinder) end
 -- Tapered tail with diagonal bracing, swept fin and stabilizer endplates.
 rod('TailBoom',Vector3.new(0,1.2,6),Vector3.new(0,3,19),1.4,teal)
 rod('TailBrace',Vector3.new(0,-1,6),Vector3.new(0,3,18),.35,cream)
 local fin=Instance.new('WedgePart');fin.Name='SweptTailFin';fin.Size=Vector3.new(.65,6,5);fin.CFrame=CFrame.new(0,5,18);fin.Color=gold;fin.Anchored=true;fin.CanCollide=false;fin.CanTouch=false;fin.CanQuery=false;fin.Parent=m
 p('Tailplane',Vector3.new(10,.35,2.8),CFrame.new(0,2.8,15.7),cream)
 for _,x in {-4.8,4.8} do p('TailEndplate',Vector3.new(.3,1.5,2.8),CFrame.new(x,3.2,15.7),teal) end
 p('Mast',Vector3.new(3,.65,.65),CFrame.new(0,5,0)*CFrame.Angles(0,0,math.pi/2),ink,Enum.PartType.Cylinder)
 p('RotorHub',Vector3.new(1,2,2),CFrame.new(0,6.3,0)*CFrame.Angles(0,0,math.pi/2),gold,Enum.PartType.Cylinder)
 local rotor=Instance.new('Model');rotor.Name='Rotor';rotor.Parent=m
 for i=0,3 do
  local cf=CFrame.new(0,6.3,0)*CFrame.Angles(0,i*math.pi/2,0)
  p('RotorBlade',Vector3.new(13,.16,1.05),cf*CFrame.new(7.3,0,0),ink,nil,rotor)
  p('RotorTip',Vector3.new(1.8,.17,1.08),cf*CFrame.new(13,0,0),gold,nil,rotor)
  rod('PitchLink',Vector3.new(0,5.7,0),(cf*CFrame.new(2,-.1,0)).Position,.13,cream,rotor)
 end;rotor.WorldPivot=CFrame.new(0,6.3,0)
 local tail=Instance.new('Model');tail.Name='TailRotor';tail.Parent=m
 for i=0,3 do local cf=CFrame.new(1,4.4,18.2)*CFrame.Angles(i*math.pi/2,0,0);p('TailBlade',Vector3.new(.16,2.8,.5),cf*CFrame.new(0,1.5,0),ink,nil,tail);p('TailTip',Vector3.new(.18,.6,.55),cf*CFrame.new(0,2.6,0),gold,nil,tail) end;tail.WorldPivot=CFrame.new(1,4.4,18.2)
 for _,s in {-1,1} do
  rod('Skid',Vector3.new(s*4.6,-4.5,6),Vector3.new(s*4.6,-4.5,-5),.45,ink)
  rod('SkiNose',Vector3.new(s*4.6,-4.5,-5),Vector3.new(s*4.6,-3.7,-7),.45,ink)
  for _,z in {-3,4} do rod('LandingStrut',Vector3.new(s*2.7,-2,z),Vector3.new(s*4.6,-4.5,z),.36,cream) end
  p('BoardingStep',Vector3.new(1.7,.25,4.7),CFrame.new(s*4.5,-3,2),gold)
  local nav=p('NavigationLight',Vector3.one*.55,CFrame.new(s*4.5,2.6,4.8),s<0 and red or Color3.fromRGB(100,255,180),Enum.PartType.Ball);nav.Material=Enum.Material.Neon
  local plaque=p('RescueBadge',Vector3.new(.15,1.8,2.5),CFrame.new(s*3.95,-.2,-3),gold)
  local sg=Instance.new('SurfaceGui');sg.Face=s>0 and Enum.NormalId.Right or Enum.NormalId.Left;sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;sg.PixelsPerStud=50;sg.Parent=plaque
  local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text='C&C\nRESCUE';label.Font=Enum.Font.FredokaOne;label.TextScaled=true;label.TextColor3=ink;label.Parent=sg
 end
 rod('WinchArm',Vector3.new(3.5,2.5,2),Vector3.new(7,2.5,2),.4,gold)
 rod('WinchBrace',Vector3.new(4,1,2),Vector3.new(6.4,2.5,2),.25,ink)
 p('WinchDrum',Vector3.new(1.6,1.2,1.2),CFrame.new(7,2,2),ink,Enum.PartType.Cylinder)
 for _,x in {6.3,7.7} do p('WinchFlange',Vector3.new(.18,1.7,1.7),CFrame.new(x,2,2),gold,Enum.PartType.Cylinder) end
 local beacon=p('Beacon',Vector3.new(.7,.6,.7),CFrame.new(0,4.8,4),red,Enum.PartType.Ball);beacon.Material=Enum.Material.Neon
 m.Parent=parent;return m
end
return A
