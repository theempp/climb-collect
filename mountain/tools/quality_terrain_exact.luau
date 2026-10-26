-- Exact run-length material/occupancy export, compared byte-for-byte on disk.
-- Spatial signatures of protected sanctuary and playable corridor, plus edited region.
-- Quantize occupancy to native 1/256 precision. Two independent modular accumulators.
local T=workspace.Terrain
local result={resolution=4,regions={}}
local domains={
 {name='legacyMountain',lo=Vector3.new(-640,-64,-640),hi=Vector3.new(640,900,640)},
 {name='sanctuary',lo=Vector3.new(3000,-64,-208),hi=Vector3.new(5200,512,1024)},
 {name='playable',lo=Vector3.new(3920,-64,-1412),hi=Vector3.new(4272,800,-208)},
 {name='landscape',lo=Vector3.new(3392,-64,-1840),hi=Vector3.new(4800,800,-208)},
}
for _,d in domains do
 local rows={};local cells=0
 for z=d.lo.Z,d.hi.Z-4,32 do
  local reg=Region3.new(Vector3.new(d.lo.X,d.lo.Y,z),Vector3.new(d.hi.X,d.hi.Y,math.min(z+32,d.hi.Z)))
  local m,o=T:ReadVoxels(reg,4);local a,b=0,0;local n=0;local solid=0;local runs={};local previous=-1;local count=0
  for i=1,#m do for j=1,#m[i] do for k=1,#m[i][j] do
   n+=1;local q=math.floor(o[i][j][k]*256+.5);local v=if q==0 then 0 else m[i][j][k].Value*512+q
   if v~=previous and count>0 then table.insert(runs,count..':'..previous);count=0 end;previous=v;count+=1
   a=(a+v)%2147483647;b=(b+v*(n%65521+1))%2147483629
   if q>0 then solid+=1 end
  end end end
  if count>0 then table.insert(runs,count..':'..previous) end
  cells+=n;table.insert(rows,{z=z,a=a,b=b,solid=solid,cells=n,rle=table.concat(runs,';')});task.wait()
 end
 result.regions[d.name]={cells=cells,rows=rows}
end
return result
