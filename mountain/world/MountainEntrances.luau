-- Review-only frontage revision. Does not resize or move home plots.
local E={version=2}
function E.layout()
 local sides={}
 for _,s in ipairs({{name='West',x=3960,outer=3438,bend=3738},{name='East',x=4232,outer=4754,bend=4454}}) do
  s.width=92;s.exitZ=-166
  s.path={{x=s.outer,y=0,z=-48},{x=s.bend,y=28,z=-108},{x=s.x,y=28,z=-166},{x=s.x,y=28,z=-182},{x=s.x,y=16,z=-210}}
  table.insert(sides,s)
 end
 return {sides=sides}
end
function E.apply(world,sanctuary)
 assert(world:GetAttribute('FreeClimbVersion') and sanctuary,'Free-climb sanctuary only')
 if world:GetAttribute('EntranceVersion')==E.version then return end
 local previous=world:FindFirstChild('MountainApproaches');if previous then previous:Destroy() end
 for _,name in ipairs({'WestSanctuaryExit','EastSanctuaryExit'}) do local exit=world.SanctuaryExits:FindFirstChild(name);if exit then exit:Destroy() end end
 local A=require(script.Parent.Art)
 local root=Instance.new('Folder');root.Name='MountainApproaches';root.Parent=world
 local stone=Color3.fromRGB(179,174,151);local pale=Color3.fromRGB(215,208,174);local green=Color3.fromRGB(153,234,182)
 local function part(name,pos,size,color,collide)
  return A.part(root,name,size,CFrame.new(pos),color,Enum.Material.Cobblestone,nil,collide)
 end
 local function ramp(name,a,b,width,thickness,color)
  local p=A.part(root,name,Vector3.new(width,thickness,(b-a).Magnitude+2),CFrame.lookAt((a+b)/2-Vector3.new(0,thickness/2,0),b-Vector3.new(0,thickness/2,0)),color,Enum.Material.Cobblestone,nil,true)
  return p
 end
 local g=E.layout();local mass=sanctuary.TerrainMassing_NoLandscaping
 -- Preserve lower planted terraces at28; bridge their front retaining wall with a broad slope.
 for _,side in ipairs(g.sides) do
  local sign=if side.name=='West' then -1 else 1
  local center=4096+sign*440
  ramp(side.name..'FrontageSlope',Vector3.new(center,0,-48),Vector3.new(center,28,-108),640,4,stone)
  -- Open the inner end of the upper retaining mass for the new physical passage.
  for _,p in ipairs(mass:GetChildren()) do
   if p.Name=='GateFlankUpper' and (p.Position.X-4096)*sign>0 then
    local outer=p.Position.X+sign*p.Size.X/2
    local inner=side.x+sign*side.width/2
    p.Size=Vector3.new(math.abs(outer-inner),p.Size.Y,p.Size.Z)
    p.Position=Vector3.new((outer+inner)/2,p.Position.Y,p.Position.Z)
   end
  end
  local landscape=sanctuary.AlpineEnvironment_Step3:FindFirstChild(side.name..'GateLandscape')
  local columns={}
  if landscape then
   -- Clear whole planted columns touched by the route, so no detached branches remain.
   for _,p in ipairs(landscape:GetChildren()) do
    if p:IsA('BasePart') and p.Name=='PlantedLowerTerrace' then
     for i=2,#side.path do
      local aa,bb=side.path[i-1],side.path[i]
      local a,b=Vector2.new(aa.x,aa.z),Vector2.new(bb.x,bb.z);local q=Vector2.new(p.Position.X,p.Position.Z)
      local t=math.clamp((q-a):Dot(b-a)/(b-a):Dot(b-a),0,1)
      if (q-(a+(b-a)*t)).Magnitude<60 then table.insert(columns,p.Position.X);break end
     end
    end
   end
   local removed=0
   for _,p in ipairs(landscape:GetChildren()) do
    if p:IsA('BasePart') then
     for _,x in ipairs(columns) do if math.abs(p.Position.X-x)<30 then p:Destroy();removed+=1;break end end
    end
   end
   root:SetAttribute(side.name..'LandscapePartsCleared',removed)
  end
  for i=2,#side.path do
   local a,b=side.path[i-1],side.path[i]
   ramp(side.name..'DirectPath_'..i,Vector3.new(a.x,a.y+.25,a.z),Vector3.new(b.x,b.y+.25,b.z),48,.5,pale)
  end
  -- Wide landing makes the entry join forgiving at either end of the slope.
  part(side.name..'MountainLanding',Vector3.new(side.x,13,-209),Vector3.new(92,6,8),stone,true)
  local exit=Instance.new('Part');exit.Name=side.name..'SanctuaryExit';exit.Size=Vector3.new(side.width,36,18)
  exit.CFrame=CFrame.new(side.x,30,side.exitZ);exit.Anchored=true;exit.CanCollide=false;exit.CanTouch=false;exit.Transparency=1;exit.Parent=world.SanctuaryExits
  local line=part(side.name..'SafeReturnLine',Vector3.new(side.x,28.6,-166),Vector3.new(48,.15,2),green,false);line.Material=Enum.Material.Neon
  for _,dx in ipairs({-28,28}) do
   local post=part(side.name..'EntranceLantern',Vector3.new(side.x+dx,35,-166),Vector3.new(3,14,3),green,true)
   post.Material=Enum.Material.Marble
   A.label(post,'SAFE RETURN\nMountain entrance',7)
  end
  local wayfinder=part(side.name..'Wayfinder',Vector3.new(side.outer+sign*30,6,-30),Vector3.new(3,12,3),green,true)
  A.label(wayfinder,'MOUNTAIN ↗\nSprint: hold Shift / mobile toggle',8)
 end
 world:SetAttribute('EntranceVersion',E.version)
end
return E
