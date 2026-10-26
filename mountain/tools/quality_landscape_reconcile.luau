-- EDIT-TIME ONLY: finish the exact Review05 recipe after stages 1, 2, 3.
-- Pass the decoded, versioned review05-recipe-correction.json evidence artifact.
-- This records native occupancy/material remnants of the original authoring iterations.
local patch=...
assert(not game:GetService('RunService'):IsRunning(),'Edit-time only')
assert(type(patch)=='table' and patch.chunks,'Expected recorded correction')
local T=workspace.Terrain
local materials={};for _,m in Enum.Material:GetEnumItems() do materials[m.Value]=m end
local prepared={};local changed=0
for _,chunk in patch.chunks do
 assert(chunk.z>=-1840 and chunk.z<=-240 and (chunk.z+1840)%32==0,'Invalid slice')
 local region=Region3.new(Vector3.new(3392,-64,chunk.z),Vector3.new(4800,800,chunk.z+32))
 local m,o=T:ReadVoxels(region,4)
 for _,e in chunk.edits do
  local index=e[1]-1;local k=index%8+1;local j=math.floor(index/8)%216+1;local i=math.floor(index/(8*216))+1
  assert(i>=1 and i<=352,'Invalid voxel')
  local x=3392+(i-.5)*4;local z=chunk.z+(k-.5)*4
  assert(x<3920 or x>=4272 or z< -1412,'Protected corridor')
  local q=math.floor(o[i][j][k]*256+.5);local current=if q==0 then 0 else m[i][j][k].Value*512+q
  assert(current==e[2] or current==e[3],'Recipe precondition mismatch')
  if current~=e[3] then
   local target=e[3];local material=materials[math.floor(target/512)];local occupancy=target%512
   assert(material and occupancy<=256,'Invalid target')
   m[i][j][k]=material;o[i][j][k]=occupancy/256;changed+=1
  end
 end
 table.insert(prepared,{region,m,o});task.wait()
end
-- Validate every precondition before making any write.
for _,chunk in prepared do T:WriteVoxels(chunk[1],4,chunk[2],chunk[3]);task.wait() end
return {changed=changed}
