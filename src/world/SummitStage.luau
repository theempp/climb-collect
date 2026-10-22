-- Additive native stage. Does not alter Terrain, routes, triggers or the final existing obstacle.
local S={}
function S.build()
 assert(not workspace.World:FindFirstChild('SummitStage'),'stage already exists')
 local m=Instance.new('Model');m.Name='SummitStage';m.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 local ink=Color3.fromRGB(39,59,73);local gold=Color3.fromRGB(255,196,52);local cream=Color3.fromRGB(244,235,205)
 local function p(name,size,cf,color,solid)
  local v=Instance.new('Part');v.Name=name;v.Size=size;v.CFrame=cf;v.Color=color;v.Material=Enum.Material.SmoothPlastic;v.Anchored=true;v.CanCollide=solid~=false;v.Parent=m;return v
 end
 local function rail(a,b)
  local mid=(a+b)/2;p('Guardrail',Vector3.new(.3,.3,(b-a).Magnitude),CFrame.lookAt(mid,b),gold)
 end
 local function deck(a,b,width)
  p('Boardwalk',Vector3.new(width,1,(b-a).Magnitude+1),CFrame.lookAt((a+b)/2,b),cream)
 end
 deck(Vector3.new(-85,3171,4),Vector3.new(-85,3171,0),10)
 local last
 for flight=0,3 do
  local x=-85+flight*12
  for i=0,13 do
   local z=flight%2==0 and -i*3.5 or -45.5+i*3.5
   local y=3171+(flight*13+i)*1.5
   local at=Vector3.new(x,y,z)
   p('CrownStep',Vector3.new(10,1.5,4),CFrame.new(at),i%4==0 and gold or cream)
   for _,side in {-1,1} do
    local post=at+Vector3.new(side*5,2.4,0);p('GuardPost',Vector3.new(.4,4.8,.4),CFrame.new(post),ink)
    if last then rail(last+Vector3.new(side*5,4.5,0),at+Vector3.new(side*5,4.5,0)) end
   end
   last=at
  end
  if flight<3 then deck(last,last+Vector3.new(12,0,0),10);last=nil end
 end
 deck(Vector3.new(-49,3249,0),Vector3.new(40,3250,12),10)
 p('TruePeakDeck',Vector3.new(25,1.5,25),CFrame.new(40,3250,12),ink)
 for _,z in {-12,12} do rail(Vector3.new(28,3254,12+z),Vector3.new(52,3254,12+z)) end
 rail(Vector3.new(52,3254,0),Vector3.new(52,3254,24))
 local zone=p('Arrival',Vector3.new(20,8,20),CFrame.new(40,3255,12),cream,false);zone.Transparency=1;zone.CanTouch=false;zone.CanQuery=false
 local point=p('Celebration',Vector3.one,CFrame.new(40,3254,12),cream,false);point.Transparency=1;point.CanQuery=false;point.CanTouch=false
 p('PeakPole',Vector3.new(.5,16,.5),CFrame.new(48,3259,18),cream)
 p('SummitPennant',Vector3.new(6,3,.2),CFrame.new(45,3265,18),gold)
 local stone=p('PeakMarker',Vector3.new(6,5,2),CFrame.new(48,3254,21),gold)
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(500,350);gui.Parent=stone
 local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text='TRUE PEAK\n3,249\nCLIMB & COLLECT';label.Font=Enum.Font.FredokaOne;label.TextSize=64;label.TextColor3=ink;label.Parent=gui
 m.Parent=workspace.World;return m
end
return S
