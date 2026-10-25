-- One deterministic landform shared by trail placement and terrain generation.
local P={}
function P.height(x,z)
 local a=math.atan2(z,x)
 local radial=math.sqrt(x*x+z*z)
 -- A connected star-shaped watershed avoids disconnected contour islands.
 -- Unequal broad ridges run continuously from the summit to the foothills.
 local width=440+65*math.sin(a*3+.5)+34*math.sin(a*5-1)+22*math.cos(a-1)
 local crown=86+15*math.sin(a*3+.5)
 local r=math.max(0,(radial-crown)/width)
 return math.max(-32,858*(1-r^1.12))
end
function P.radius(angle,height)
 local cx,cz=math.cos(angle),math.sin(angle)
 local outer=800
 for r=784,0,-16 do
  if P.height(cx*r,cz*r)>=height then
   local inner=r
   for _=1,20 do
    local mid=(inner+outer)*.5
    if P.height(cx*mid,cz*mid)>=height then inner=mid else outer=mid end
   end
   return (inner+outer)*.5
  end
  outer=r
 end
 return 0
end
return P
