-- Original primitive merchandise. Shared by viewport portraits, plinths and equipped cosmetics.
local A={}
local gold,cream,purple,blue,ink=Color3.fromRGB(255,197,64),Color3.fromRGB(255,239,161),Color3.fromRGB(129,64,196),Color3.fromRGB(64,191,221),Color3.fromRGB(39,45,67)
function A.make(kind,parent,cf,scale)
 local m=Instance.new("Model");m.Name="Merchandise_"..kind
 local function part(name,size,pos,color,shape,rotation)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(pos)*(rotation or CFrame.identity);p.Color=color;p.Material=Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  if shape then p.Shape=shape end;p.Parent=m;return p
 end
 local function lantern(x)
  part("Glass",Vector3.new(1.05,1.5,1.05),Vector3.new(x,1.35,0),cream)
  for _,y in ipairs({0.5,2.2}) do part("LanternRim",Vector3.new(1.45,0.22,1.45),Vector3.new(x,y,0),y<1 and blue or gold) end
  for _,sx in ipairs({-0.59,0.59}) do for _,sz in ipairs({-0.59,0.59}) do part("Cage",Vector3.new(0.09,1.6,0.09),Vector3.new(x+sx,1.35,sz),gold) end end
  for _,sx in ipairs({-0.4,0.4}) do part("Handle",Vector3.new(0.1,0.55,0.1),Vector3.new(x+sx,2.55,0),ink) end
  part("HandleTop",Vector3.new(0.9,0.1,0.1),Vector3.new(x,2.85,0),ink)
  part("Flame",Vector3.new(0.35,0.8,0.12),Vector3.new(x,1.3,-0.56),gold,Enum.PartType.Ball)
 end
 local function flag(x,z)
  part("Pole",Vector3.new(0.12,3.5,0.12),Vector3.new(x,1.75,z),gold)
  part("Finial",Vector3.new(0.26,0.26,0.26),Vector3.new(x,3.57,z),cream,Enum.PartType.Ball)
  part("Banner",Vector3.new(1.85,1.25,0.1),Vector3.new(x+0.92,2.65,z),purple)
  part("Hem",Vector3.new(1.85,0.12,0.14),Vector3.new(x+0.92,2.05,z),gold)
  local w=Instance.new("WedgePart");w.Name="Mountain";w.Size=Vector3.new(0.16,0.72,0.8);w.CFrame=CFrame.new(x+0.92,2.65,z-0.12)*CFrame.Angles(0,math.pi/2,0);w.Color=cream;w.Anchored=true;w.CanCollide=false;w.CanQuery=false;w.CanTouch=false;w.Parent=m
 end
 if kind=="bundle" then flag(-0.2,0.6);lantern(-0.7)
 elseif kind=="lantern" or kind=="lamp" then lantern(0)
 elseif kind=="flag" or kind=="banner" then flag(-0.8,0)
 elseif kind=="trail" then
  for i=1,5 do local x=math.sin(i)*0.7;local y=i*0.55;part("Star",Vector3.new(0.55,0.55,0.18),Vector3.new(x,y,0),gold,nil,CFrame.Angles(0,0,math.pi/4));part("Spark",Vector3.new(0.18,0.7,0.2),Vector3.new(x,y,0),cream) end
 elseif kind:match("upgrade") then
  local medal=part("Medal",Vector3.new(0.3,2.3,2.3),Vector3.new(0,1.8,0),gold,Enum.PartType.Cylinder,CFrame.Angles(0,math.pi/2,0))
  local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Right;gui.CanvasSize=Vector2.new(200,200);gui.Parent=medal
  local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=((tonumber(kind:match("%d+")) or 0)+1)*2 .."×";t.TextColor3=ink;t.Font=Enum.Font.FredokaOne;t.TextScaled=true;t.Parent=gui
  for _,x in ipairs({-0.4,0.4}) do part("Ribbon",Vector3.new(0.55,1.1,0.16),Vector3.new(x,0.55,0.15),blue,nil,CFrame.Angles(0,0,x)) end
 else
  for i=1,7 do part("Coin",Vector3.new(0.24,1,1),Vector3.new((i%3-1)*0.7,0.4+math.floor((i-1)/3)*0.5,(i%2)*0.25),gold,Enum.PartType.Cylinder,CFrame.Angles(0,0,math.pi/2)) end
  if kind=="coins2000" then part("Chest",Vector3.new(2.6,1.2,1.4),Vector3.new(0,0.4,0.4),blue);part("Clasp",Vector3.new(0.4,0.6,0.1),Vector3.new(0,0.6,-0.35),gold) end
 end
 m.WorldPivot=CFrame.identity
 if scale and scale~=1 then m:ScaleTo(scale) end
 m:PivotTo(cf or CFrame.identity);m.Parent=parent;return m
end
return A
