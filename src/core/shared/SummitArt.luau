-- Original expedition rescue helicopter, constructed from native parts; no toolbox scripts.
local A={}
function A.helicopter(parent)
 local m=Instance.new('Model');m.Name='SummitRescue';local cream=Color3.fromRGB(255,240,193);local teal=Color3.fromRGB(20,160,165);local ink=Color3.fromRGB(28,45,63);local gold=Color3.fromRGB(255,192,49)
 local function p(name,size,cf,color,shape)
  local v=Instance.new('Part');v.Name=name;v.Size=size;v.CFrame=cf;v.Color=color;v.Material=Enum.Material.SmoothPlastic;v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;if shape then v.Shape=shape end;v.Parent=m;return v
 end
 local body=p('Cabin',Vector3.new(9,7,14),CFrame.new(),teal,Enum.PartType.Ball);m.PrimaryPart=body
 p('CreamBelly',Vector3.new(8.2,3.4,12.4),CFrame.new(0,-1.7,0),cream,Enum.PartType.Ball)
 local glass=p('PanoramicCockpit',Vector3.new(7.8,4.8,6),CFrame.new(0,.7,-5.3),Color3.fromRGB(70,190,217),Enum.PartType.Ball);glass.Material=Enum.Material.Glass;glass.Transparency=.12
 p('TailBoom',Vector3.new(2.4,2.4,14),CFrame.new(0,1.4,11),teal)
 p('TailFin',Vector3.new(.65,6,4),CFrame.new(0,4,17),gold)
 p('Tailplane',Vector3.new(10,.5,3),CFrame.new(0,1.4,14),cream)
 p('RotorMast',Vector3.new(.8,4,.8),CFrame.new(0,4.3,0),ink)
 local rotor=Instance.new('Model');rotor.Name='Rotor';rotor.Parent=m
 for i=0,1 do local blade=p('MainBlade',Vector3.new(30,.25,1.1),CFrame.new(0,6.3,0)*CFrame.Angles(0,i*math.pi/2,0),ink);blade.Parent=rotor end
 rotor.WorldPivot=CFrame.new(0,6.3,0)
 local tailRotor=Instance.new('Model');tailRotor.Name='TailRotor';tailRotor.Parent=m
 for i=0,1 do local blade=p('TailBlade',Vector3.new(.25,7,.6),CFrame.new(1.6,4,17)*CFrame.Angles(i*math.pi/2,0,0),ink);blade.Parent=tailRotor end;tailRotor.WorldPivot=CFrame.new(1.6,4,17)
 for _,side in {-1,1} do
  p('LandingSkid',Vector3.new(.5,.5,15),CFrame.new(side*4,-5,0),ink)
  for _,z in {-3,4} do p('SkidStrut',Vector3.new(.45,3,.45),CFrame.new(side*3.6,-3.8,z)*CFrame.Angles(0,0,side*-.28),cream) end
  p('Door',Vector3.new(.18,4,4.2),CFrame.new(side*4.4,-.1,1.2),cream)
  p('DoorWindow',Vector3.new(.2,2,3.4),CFrame.new(side*4.55,.65,1.2),Color3.fromRGB(45,113,145))
  p('DoorHandle',Vector3.new(.22,.2,1),CFrame.new(side*4.7,-1.3,1.5),ink)
  local plaque=p('ExpeditionBadge',Vector3.new(.22,1.5,2.1),CFrame.new(side*4.5,-.6,-2),gold)
  local light=p('NavigationLight',Vector3.new(.6,.5,.6),CFrame.new(side*4.4,2,2),side<0 and Color3.fromRGB(248,92,67) or Color3.fromRGB(80,245,181));light.Material=Enum.Material.Neon
 end
 p('WinchArm',Vector3.new(4,.5,.5),CFrame.new(5.5,2,2),gold)
 p('WinchDrum',Vector3.new(1.2,1.2,1.2),CFrame.new(7,2,2),ink,Enum.PartType.Ball)
 m.Parent=parent;return m
end
return A
