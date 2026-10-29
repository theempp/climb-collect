local H=game.HttpService;local RS=game.ReplicatedStorage;local R=require(RS.CC_Core.TraversalRules)
local open,closed,gates={},{},{}
local function add(route,points) if #points>1 then table.insert((route=='Ledge' or route=='Spire') and closed or open,{route=route,points=points}) end end
for _,sv in RS.CC_Route:GetChildren() do local points={};for row in sv.Value:gmatch('[^;]+') do local x,y,z=row:match('([^,]+),([^,]+),([^,]+)');table.insert(points,{tonumber(x),tonumber(y),tonumber(z)}) end;add(sv.Name,points) end
for _,sv in RS.CC_Track:GetChildren() do for _,t in H:JSONDecode(sv.Value) do local points={};for _,n in t.nodes do if n.p then table.insert(points,n.p) end end;add(sv.Name,points) end end
for _,sv in RS.CC_TraversalDefs:GetChildren() do local t=H:JSONDecode(sv.Value);local points={t.entry};for _,h in t.holds do table.insert(points,h.p) end;table.insert(points,t.exit);add(t.route,points) end
for _,g in workspace.World:GetDescendants() do if g:IsA('Model') and g:GetAttribute('ComingSoon') and g:FindFirstChild('Board') then table.insert(gates,{cf=g:GetPivot(),route=g:GetAttribute('Route') or g.Name:gsub('Gate_','')}) end end
local oi,ci=R.routeIndex(open,64),R.routeIndex(closed,64)
local ray=RaycastParams.new();ray.RespectCanCollide=true;ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={game.Players:GetPlayers()[1].Character}
local function allowed(x,z)
 local hit=workspace:Raycast(Vector3.new(x,150,z),Vector3.new(0,-180,0),ray)
 if not hit or hit.Position.Y>55 or hit.Position.Y<45 then return false end
 local at={x,52,z};local c=R.closedRouteAt(ci,oi,at)
 for _,g in gates do
  local p=g.cf:PointToObjectSpace(Vector3.new(x,52,z));if c==g.route and R.closedGateApproach(p.X,p.Y,p.Z) then c=nil end
  local entrance=math.abs(p.X)<24 and p.Z<-2 and p.Z>-50 and p.Y>-6 and p.Y<32
  if entrance and R.nearestRoute(oi,at,24) then entrance=false end
  if entrance or c==g.route then return false end
 end
 return true
end
local function key(x,z) return x..':'..z end
local queue={{0,2100}};local prev={[key(0,2100)]=false};local target
for _,v in queue do
 if (Vector2.new(v[1]+227.2,v[2]-1812.2)).Magnitude<15 then target=v;break end
 for _,d in {{10,0},{-10,0},{0,-10},{0,10}} do
  local x,z=v[1]+d[1],v[2]+d[2];local k=key(x,z)
  local obstacle=workspace:Blockcast(CFrame.new(v[1],54,v[2]),Vector3.new(4,5,4),Vector3.new(d[1],0,d[2]),ray)
  if x>=-400 and x<=400 and z>=1740 and z<=2120 and prev[k]==nil and not obstacle and allowed(x,z) then prev[k]=v;table.insert(queue,{x,z}) end
 end
end
assert(target,'No open ground approach')
local path={};while target do table.insert(path,1,target);target=prev[key(target[1],target[2])] end
local turns={};for i,v in path do if i==1 or i==#path or v[1]-path[i-1][1]~=path[i+1][1]-v[1] or v[2]-path[i-1][2]~=path[i+1][2]-v[2] then table.insert(turns,v) end end
return {path=turns,points=#path}
