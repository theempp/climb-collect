local P={}
function P.build()
 local world=workspace.World;if world:FindFirstChild('ExpeditionPolish') then return end
 local root=Instance.new('Model');root.Name='ExpeditionPolish'
 local colors={Color3.fromRGB(32,182,181),Color3.fromRGB(250,192,60),Color3.fromRGB(153,112,218)}
 local function part(name,size,cf,color)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.Parent=root;return p
 end
 local function sign(p,text,face)
  local g=Instance.new('SurfaceGui');g.Face=face or Enum.NormalId.Right;g.CanvasSize=Vector2.new(600,450);g.Parent=p
  local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.Text=text;t.Font=Enum.Font.FredokaOne;t.TextColor3=Color3.fromRGB(27,46,64);t.TextScaled=true;t.Parent=g
 end
 for i,v in {{-83.85,54,2016},{-91.85,68,2016},{-99.85,87,2016}} do
  local p=part('PracticeNumber'..i,Vector3.new(.15,5,5),CFrame.new(table.unpack(v)),colors[i]);p.CanCollide=false;sign(p,tostring(i))
 end
 local a,b=Vector3.new(-52.8,59.2,2006.5),Vector3.new(-88,59.2,2011)
 part('PracticeLoopBridge',Vector3.new(4,1,(a-b).Magnitude),CFrame.lookAt((a+b)/2,b),colors[1])
 local p=part('LoopSign',Vector3.new(.2,3,4),CFrame.new(-87,62,2010),colors[2]);p.CanCollide=false;sign(p,'LOOP\n→ 2')
 -- Five original earned rewards displayed as a small collection, distinct from priced Exchange offers.
 local catalog=require(game.ReplicatedStorage.CC_Core.EarnedCosmetics);local art=require(game.ReplicatedStorage.CC_Core.EarnedArt)
 for i,id in {'practice_pennant','summit_first','summit_5','summit_15','summit_30'} do
  local at=Vector3.new(-65+(i-1)*6,50,2068)
  local plinth=part('EarnedPlinth_'..id,Vector3.new(4.5,2,4.5),CFrame.new(at),colors[(i-1)%3+1]);plinth.CanCollide=false
  local m=art.make(id,root,CFrame.new(at+Vector3.new(0,2,0)));m:ScaleTo(id=='summit_30' and 1.8 or 1.3)
  local g=Instance.new('BillboardGui');g.Name='EarnedLabel';g.Size=UDim2.fromOffset(120,56);g.StudsOffsetWorldSpace=Vector3.new(0,5,0);g.MaxDistance=35;g.Parent=plinth
  local text=Instance.new('TextLabel');text.Size=UDim2.fromScale(1,1);text.BackgroundColor3=Color3.fromRGB(255,244,207);text.TextColor3=Color3.fromRGB(29,46,64);text.Text=catalog[id].name..'\nEARNED';text.Font=Enum.Font.FredokaOne;text.TextSize=14;text.TextWrapped=true;text.Parent=g
 end
 root.Parent=world;return #root:GetDescendants()
end
return P
