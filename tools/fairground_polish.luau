-- Review art dressing; deliberately placed islands leave the social court unobstructed.
return function()
 local f=workspace.World.Fairground
 assert(not f:FindFirstChild('GardenIslands'),'already dressed')
 local m=Instance.new('Model');m.Name='GardenIslands';m.Parent=f
 local function p(name,size,pos,color,shape)
  local q=Instance.new('Part');q.Name=name;q.Size=size;q.Position=pos;q.Color=Color3.fromRGB(table.unpack(color));q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.CanQuery=false;q.Material=Enum.Material.SmoothPlastic;if shape then q.Shape=shape end;q.Parent=m;return q
 end
 for _,v in {{-82,2101},{82,2045},{-83,2040},{24,2115},{-19,1974}} do
  local x,z=v[1],v[2]
  p('RaisedGarden',Vector3.new(17,1.5,9),Vector3.new(x,49.5,z),{41,72,76})
  p('VelvetMoss',Vector3.new(15,1,7),Vector3.new(x,50.5,z),{71,162,97})
  for i=-2,2 do
   p('LeafCushion',Vector3.new(4,2.5,4),Vector3.new(x+i*3,52,z),{49,131+i*8,99},Enum.PartType.Ball)
   local stem=Vector3.new(x+i*3,54,z)
   p('GoldenFlower',Vector3.new(1.8,.6,1.8),stem,{255,191+i*8,76},Enum.PartType.Ball)
   p('FlowerHeart',Vector3.new(.65,.65,.65),stem+Vector3.yAxis*.35,{255,243,196},Enum.PartType.Ball)
  end
 end
 -- An oversized lantern, lens, handle and tripod ground the expedition theme.
 local at=Vector3.new(24,49,2114)
 for _,dx in {-4,4} do p('LanternFoot',Vector3.new(1,4,1),at+Vector3.new(dx,2,0),{38,53,69}) end
 p('LanternBase',Vector3.new(11,2,8),at+Vector3.new(0,5,0),{255,183,54})
 local lens=p('LanternLens',Vector3.new(8,10,6),at+Vector3.new(0,11,0),{255,236,175});lens.Material=Enum.Material.Glass;lens.Transparency=.15
 p('LanternCap',Vector3.new(11,2,8),at+Vector3.new(0,17,0),{22,174,173})
 for _,dx in {-4.5,4.5} do p('LanternFrame',Vector3.new(.8,12,.8),at+Vector3.new(dx,11,3.3),{38,53,69}) end
 for i=0,11 do local a=i*math.pi/11;p('Handle',Vector3.new(1,1,1.4),at+Vector3.new(5*math.cos(a),18+5*math.sin(a),0),{255,183,54},Enum.PartType.Ball) end
 -- Compass rose points directly toward the physical mountain entrance.
 for i=0,7 do
  local a=i*math.pi/4
  local q=p('CompassRay',Vector3.new(1.2,.12,i%2==0 and 14 or 9),Vector3.new(math.sin(a)*10,49.12,2050+math.cos(a)*10),i%2==0 and {22,174,173} or {238,112,42});q.CFrame*=CFrame.Angles(0,a,0)
 end
 local a=f.Anchors
 for _,id in {'Exchange_Bundle','Exchange_Flag','Exchange_Trail'} do a[id].CFrame+=Vector3.new(-7,0,14) end
 f.Exchange:PivotTo(f.Exchange:GetPivot()+Vector3.new(-7,0,14))
 workspace.World.CommerceDisplays:Destroy()
 require(game.ServerScriptService.CC_CoreServer.CommerceDisplays:Clone()).build()
 a.PracticeStart.CFrame+=Vector3.new(10,0,12)
 return #m:GetDescendants()
end
