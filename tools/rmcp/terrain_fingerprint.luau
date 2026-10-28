-- Read-only whole-terrain fingerprint (gap-encoded, occupancy quantized to 16 bits).
local T=workspace.Terrain
local AIR=Enum.Material.Air
local X0,X1,Z0,Z1,Y0,Y1=-1280,1280,-1280,1280,-128,1664
local occ,h1,h2,gap=0,17,29,0
local t0=os.clock()
local miny,maxy,minx,maxx,minz,maxz=math.huge,-math.huge,math.huge,-math.huge,math.huge,-math.huge
for bx=X0,X1-1,64 do for bz=Z0,Z1-1,64 do
 local m,o=T:ReadVoxels(Region3.new(Vector3.new(bx,Y0,bz),Vector3.new(bx+64,Y1,bz+64)),4)
 local sy=#o[1]
 for x=1,16 do local ox,mx=o[x],m[x] for y=1,sy do local oy,my=ox[y],mx[y] for z=1,16 do
  local v=oy[z];local mat=my[z]
  if v>0 or mat~=AIR then
   occ+=1
   local n=mat.Value*65536+math.round(v*65535)
   h1=(h1*131+gap)%2147483647;h1=(h1*131+n)%2147483647
   h2=(h2*137+gap)%2147483629;h2=(h2*137+n)%2147483629
   gap=0
   local wy=Y0+(y-1)*4;if wy<miny then miny=wy end;if wy>maxy then maxy=wy end
   local wx=bx+(x-1)*4;if wx<minx then minx=wx end;if wx>maxx then maxx=wx end
   local wz=bz+(z-1)*4;if wz<minz then minz=wz end;if wz>maxz then maxz=wz end
  else gap+=1 end
 end end end
end task.wait() end
return string.format('occupied=%d of CountCells=%d h1=%d h2=%d bounds x[%d,%d] y[%d,%d] z[%d,%d] %.1fs',occ,T:CountCells(),h1,h2,minx,maxx,miny,maxy,minz,maxz,os.clock()-t0)
