-- Geological relief on the connected ridges, measured against actual terrain faces.
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local A=require(script.Parent.Art)
local M={}
local function extent(cf,size)
 local e=Vector3.zero
 for _,v in ipairs({cf.RightVector*size.X/2,cf.UpVector*size.Y/2,cf.LookVector*size.Z/2}) do e+=Vector3.new(math.abs(v.X),math.abs(v.Y),math.abs(v.Z)) end
 return e
end
function M.apply(world)
 assert(game.PlaceId==0 and not game:GetService('RunService'):IsRunning(),'Local Edit only')
 assert(world.Name=='ImpossibleMountain' and not world:FindFirstChild('RidgeRockwork'),'Wrong world or already applied')
 local clearance=require(script.Parent.ArtClearance).build(world,96)
 local protected={}
 for _,p in ipairs(world:GetDescendants()) do
  if p:IsA('BasePart') and (p.CanCollide or p:FindFirstChildOfClass('ProximityPrompt')) then
   table.insert(protected,{p.Position,extent(p.CFrame,p.Size)})
  end
 end
 local function clear(cf,size)
  local e=extent(cf,size)
  if clearance.distance(cf.Position)<size.Magnitude*.5+3 then return false end
  for _,b in ipairs(protected) do
   local d=cf.Position-b[1];local q=b[2]
   if math.abs(d.X)<e.X+q.X+7 and math.abs(d.Z)<e.Z+q.Z+7 and d.Y+e.Y> -q.Y-2 and d.Y-e.Y<q.Y+14 then return false end
  end
  return true
 end
 local root=Instance.new('Folder');root.Name='RidgeRockwork';root.Parent=world
 local terrain=RaycastParams.new();terrain.FilterType=Enum.RaycastFilterType.Include;terrain.FilterDescendantsInstances={workspace.Terrain}
 local rng=Random.new(241020);local stats={rocks=0,rejected=0,plants=0}
 local function rock(cf,size,color,parent)
  if not clear(cf,size) then stats.rejected+=1;return end
  local model=Instance.new('Model');model.Name='RootedCliff'
  local function triangle(a,b,c,tint)
   local ab,ac,bc=b-a,c-a,c-b
   if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
   elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
   ab,ac,bc=b-a,c-a,c-b
   local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=back:Cross(right)
   local h=math.abs(ab:Dot(up))
   for _,s in ipairs({{(a+b)/2,right,up,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,up,-back,math.abs(ac:Dot(back))}}) do
    local p=Instance.new('WedgePart');p.Name='StoneFace';p.Size=Vector3.new(.05,h,s[5]);p.CFrame=CFrame.fromMatrix(s[1],s[2],s[3],s[4]);p.Color=tint;p.Material=Enum.Material.Slate
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=model
   end
  end
  local lower,upper={},{}
  for i=1,6 do
   local a=(i-1)*math.pi/3;local r=.43+.05*math.sin(i*2.4)
   lower[i]=cf:PointToWorldSpace(Vector3.new(math.cos(a)*size.X*r,-size.Y*.5,math.sin(a)*size.Z*r))
   upper[i]=cf:PointToWorldSpace(Vector3.new(math.cos(a)*size.X*r*.72+size.X*.08,size.Y*(.29+.10*math.sin(i*1.7)),math.sin(a)*size.Z*r*.72))
  end
  local tip=cf:PointToWorldSpace(Vector3.new(size.X*.06,size.Y*.46,0));local base=cf:PointToWorldSpace(Vector3.new(0,-size.Y*.5,0))
  for i=1,6 do
   local n=i%6+1;local tint=color:Lerp(Color3.fromRGB(206,207,195),.025*(i%3))
   triangle(lower[i],lower[n],upper[i],tint);triangle(lower[n],upper[n],upper[i],tint)
   triangle(upper[i],upper[n],tip,tint);triangle(lower[n],lower[i],base,tint)
  end
  model.Parent=parent
  stats.rocks+=1
 end
 -- Staggered, unequal outcrops interrupt long horizontal faces. Every mass
 -- embeds its rear half into a measured terrain face; no floating fins.
 for band=1,6 do
  local group=Instance.new('Folder');group.Name=C.kingdoms[band].id;group.Parent=root
  for j=1,16 do
   local angle=j*math.pi*2/16+.21*band+.12*math.sin(j*2.1)
   local out=Vector3.new(math.cos(angle),0,math.sin(angle))
   local y=28+(band-1)*136+rng:NextNumber(8,100)
   local hit=workspace:Raycast(out*780+Vector3.new(0,y,0),-out*760,terrain)
   if hit then
    local h=rng:NextNumber(35,70);local width=rng:NextNumber(42,75);local depth=rng:NextNumber(32,48)
    local pos=hit.Position-out*depth*.08-Vector3.new(0,h*.12,0)
    local cf=CFrame.lookAt(pos,pos-out)*CFrame.Angles(0,rng:NextNumber(-.25,.25),rng:NextNumber(-.27,.27))
    local color=workspace.Terrain:GetMaterialColor(hit.Material):Lerp(Color3.fromRGB(126,134,128),.40)
    local backed=true
    for _,dy in ipairs({-h*.35,h*.25}) do
     local probe=workspace:Raycast(out*780+Vector3.new(0,y+dy,0),-out*760,terrain)
     if not probe or (probe.Position-hit.Position).Magnitude>h*.7+depth*.5 then backed=false end
    end
    if backed then rock(cf,Vector3.new(width,h,depth),color,group) else stats.rejected+=1 end
   end
  end
  task.wait()
 end
 -- Underhang clusters break the polygonal shelf fascia without creating
 -- apparent footing beyond the deliberately marked, colliding top surface.
 for ki,k in ipairs(C.kingdoms) do
  local group=root[k.id];local q=C.route(ki,.875)
  local out=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
  local center=world[k.name].ArenaFloor.Position+Vector3.new(0,2.5,0)
  local frame=CFrame.lookAt(center,center-out)
  for j=1,9 do
   local a=(j-1)*math.pi/8;local x=math.cos(a)*39;local z=48+math.sin(a)*34
   rock(frame*CFrame.new(x,-18-rng:NextNumber(0,7),z)*CFrame.Angles(0,a,.06),Vector3.new(19+rng:NextNumber(0,8),25+rng:NextNumber(0,12),22),A.color(k.rock):Lerp(Color3.fromRGB(185,186,175),.3),group)
  end
  task.wait()
 end
 root:SetAttribute('Revision',1);root:SetAttribute('Report',game.HttpService:JSONEncode(stats))
 return stats
end
return M
