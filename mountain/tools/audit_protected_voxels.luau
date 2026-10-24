-- Read-only fingerprint of the expanded gameplay corridors touched by Sculpt's tile envelope.
local world=workspace.ImpossibleMountain
local bins={}
local function key(x,y,z) return x..':'..y..':'..z end
for _,p in ipairs(world:GetDescendants()) do
 if p:IsA('BasePart') and (p.CanCollide or p:FindFirstChildOfClass('ProximityPrompt')) then
  local extent=Vector3.zero
  for _,a in ipairs({p.CFrame.RightVector*p.Size.X/2,p.CFrame.UpVector*p.Size.Y/2,p.CFrame.LookVector*p.Size.Z/2}) do extent+=Vector3.new(math.abs(a.X),math.abs(a.Y),math.abs(a.Z)) end
  local lo=p.Position-extent-Vector3.new(16,20,16);local hi=p.Position+extent+Vector3.new(16,22,16)
  for x=math.floor(lo.X/16),math.floor(hi.X/16) do for y=math.floor(lo.Y/16),math.floor(hi.Y/16) do for z=math.floor(lo.Z/16),math.floor(hi.Z/16) do bins[key(x,y,z)]=true end end end
 end
end
local count,occupied,h1,h2=0,0,17,29
for bx=-544,512,64 do for bz=-544,512,64 do
 local near=math.max(0,Vector2.new(bx+32,bz+32).Magnitude-46);local far=near+92
 local bottom=math.max(-32,math.floor(((489-far)/.4-160)/4)*4)
 local top=math.min(840,math.ceil(((489-near)/.4+90)/4)*4)
 if top>bottom and far>110 then
  local materials,occupancy=workspace.Terrain:ReadVoxels(Region3.new(Vector3.new(bx,bottom,bz),Vector3.new(bx+64,top,bz+64)),4)
  for x=1,16 do for z=1,16 do
   local wx=bx+(x-.5)*4;local wz=bz+(z-.5)*4
   if Vector2.new(wx,wz).Magnitude>115 then for y=1,#occupancy[x] do
    local wy=bottom+(y-.5)*4
    if bins[key(math.floor(wx/16),math.floor(wy/16),math.floor(wz/16))] then
     count+=1;if occupancy[x][y][z]>0 then occupied+=1 end
     local n=materials[x][y][z].Value*65536+math.round(occupancy[x][y][z]*65535)
     h1=(h1*131+n)%2147483647;h2=(h2*137+n)%2147483629
    end
   end end
  end end
 end
 task.wait()
end end
return {cells=count,occupied=occupied,hash1=h1,hash2=h2,scope='Expanded gameplay corridor voxels within sculpt tile envelope; occupancy quantized to 16 bits; non-cryptographic fingerprints'}
