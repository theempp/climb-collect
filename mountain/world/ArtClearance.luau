-- Shared conservative clearance for baked art, including moving-platform riders.
local M={}
local function key(x,y,z) return x..':'..y..':'..z end
function M.build(world,feather)
 local grid={};local boxes={};feather=feather or 36
 local function add(lo,hi)
  lo=Vector3.new(math.floor(lo.X/16)*16,math.floor(lo.Y/16)*16,math.floor(lo.Z/16)*16)
  hi=Vector3.new((math.floor(hi.X/16)+1)*16,(math.floor(hi.Y/16)+1)*16,(math.floor(hi.Z/16)+1)*16)
  local box={lo,hi};table.insert(boxes,box)
  for x=math.floor((lo.X-feather)/64),math.floor((hi.X+feather)/64) do for y=math.floor((lo.Y-feather)/64),math.floor((hi.Y+feather)/64) do for z=math.floor((lo.Z-feather)/64),math.floor((hi.Z+feather)/64) do
   local id=key(x,y,z);grid[id]=grid[id] or {};table.insert(grid[id],box)
  end end end
 end
 for _,p in ipairs(world:GetDescendants()) do
  if p:IsA('BasePart') and (p.CanCollide or p:FindFirstChildOfClass('ProximityPrompt')) then
   local e=Vector3.zero
   for _,v in ipairs({p.CFrame.RightVector*p.Size.X/2,p.CFrame.UpVector*p.Size.Y/2,p.CFrame.LookVector*p.Size.Z/2}) do e+=Vector3.new(math.abs(v.X),math.abs(v.Y),math.abs(v.Z)) end
   add(p.Position-e-Vector3.new(16,20,16),p.Position+e+Vector3.new(16,22,16))
   if p:GetAttribute('Kind')=='Moving' then
    local axis=Vector3.new(p:GetAttribute('AxisX'),0,p:GetAttribute('AxisZ'))*34
    local radius=math.sqrt(p.Size.X^2+p.Size.Z^2)/2+16
    local center=p.Position+axis/2;local extent=Vector3.new(math.abs(axis.X)/2+radius,30,math.abs(axis.Z)/2+radius)
    add(center-extent,center+extent)
   end
  end
 end
 local function distance(pos)
  local nearest=feather
  for _,b in ipairs(grid[key(math.floor(pos.X/64),math.floor(pos.Y/64),math.floor(pos.Z/64))] or {}) do
   local lo,hi=b[1],b[2]
   local dx=math.max(lo.X-pos.X,0,pos.X-hi.X);local dy=math.max(lo.Y-pos.Y,0,pos.Y-hi.Y);local dz=math.max(lo.Z-pos.Z,0,pos.Z-hi.Z)
   local d=math.sqrt(dx*dx+dy*dy+dz*dz);nearest=math.min(nearest,d)
   if nearest==0 then return 0 end
  end
  return nearest
 end
 return {boxes=boxes,distance=distance,weight=function(pos) local v=distance(pos)/feather;return v*v*(3-2*v) end}
end
return M
