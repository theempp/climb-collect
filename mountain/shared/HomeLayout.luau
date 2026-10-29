-- Home-base layout C (plan 2026-10-29 §2): 8 plots of 80x100 on a cross-shaped commons, one gate at the mountain end.
-- Pure numbers (no Roblox types) so CLI tests and the server read the same layout.
-- Plot local frame: X along the frontage (80), Z = depth (100), front edge at local z=-50 faces the vertical street.
-- World: the vertical street runs along z on x=axisX; the horizontal street (H) crosses it between rows 2 and 3.
local L={version=2,axisX=4096,groundY=16,plotWidth=80,plotDepth=100,
 promenadeWidth=70,channelWidth=12,laneWidth=29,escapeWidth=32,floorName='Plot_80x100',
 -- Shared garden strip between the two plots of a block; gate plaza depth; H street width (lanes 22 + channel 12 + 22).
 strip=16,gatePlaza=40,crossWidth=56,crossLane=22,armReach=195,endPlaza=60,crossPool=26,
 -- The gate stands on the existing center sanctuary exit line (z -166); north of z -157 is mountain.
 gate={x=4096,z=-166,opening=150,towerWidth=26,towerDepth=24,height=72},northZ=-157,
 -- v1 basin kept (owner Q5): its terrain berms are written against these extents and are not rewritten.
 basin={halfX=215,southZ=436},
 -- Old row: farthest spawn walked ~722 studs to its gate (Review02 frontage path).
 previousFarthestWalk=722,
}
L.gatePlazaZ0=L.gate.z+L.gate.towerDepth/2
L.firstZ=L.gatePlazaZ0+L.gatePlaza
-- Rows by frontage: block A = rows 1-2 (strip between), H street, block B = rows 3-4.
do
 local w,s=L.plotWidth,L.strip
 local r1=L.firstZ;local r2=r1+w+s;local cross=r2+w;local r3=cross+L.crossWidth;local r4=r3+w+s
 L.rows={r1+w/2,r2+w/2,r3+w/2,r4+w/2}
 L.cross={z0=cross,z1=cross+L.crossWidth,z=cross+L.crossWidth/2}
 L.southZ=r4+w
 L.stripZ={{r1+w,r2},{r3+w,r4}}
end
L.plots={}
for i=1,8 do
 -- Odd slots west, even east; slot 1-2 nearest the gate so the first players are closest.
 local side=if i%2==1 then -1 else 1
 local row=math.ceil(i/2)
 local yaw=if side<0 then -math.pi/2 else math.pi/2
 L.plots[i]={index=i,side=side,row=row,yaw=yaw,
  x=L.axisX+side*(L.promenadeWidth/2+L.plotDepth/2),z=L.rows[row]}
end
-- Plot contents in plot-local studs (§2 fit table). Rects are full sizes; x,z are centres.
L.contents={
 spawn={x=0,z=-40,size=6},
 services={{kind='Incubator',x=-29,z=26,size=3,y=6},{kind='Training',x=29,z=26,size=3,y=6}}, -- y = prompt-host centre above the floor (intel B10, PROPOSED; Training 10 -> 6 so the prompt reaches from the pen gate, P4 walk test)
 lodge={x=0,z=27,width=35,depth=30,overhang=5.75},
 frontWall={z0=-50,z1=-47.2,entryHalf=18},
 -- Habitat yard: 3 columns x 2 rows of pads either side of an east-west conveyor spine.
 yard={minX=-26,maxX=26,minZ=-30,maxZ=6},
 habitat={pad={w=15,d=12},rim={w=16,d=13}},
 habitats={{x=-18,z=-23.5},{x=0,z=-23.5},{x=18,z=-23.5},{x=-18,z=-.5},{x=0,z=-.5},{x=18,z=-.5}},
 spine={x=0,z=-12,width=52,depth=6},
 machines={{name='Processor',x=-18},{name='Sorter',x=0},{name='Collector',x=18}},machine={w=5,d=4,z=-12},
 -- Bank plinth is joined to the spine end on purpose (eggs roll to the bank).
 bank={x=31,z=-12,width=14,depth=8},
 hatchery={x=-29,z=26,size=14},
 pen={x=29,z=26,size=14},
 -- Reserved for the daily workout track (Q8, not built); too short for a run; kept clear of the side wall (x 37.2..40).
 workout={x=29,z=42,width=14,depth=4},
 decorSize=3,
 decor={
  {x=-30,z=-44.5},{x=-22,z=-44.5},{x=-14,z=-44.5},{x=14,z=-44.5},{x=22,z=-44.5},{x=30,z=-44.5},
  {x=-33,z=-26},{x=-33,z=-17},{x=-33,z=-8},{x=-33,z=1},{x=-33,z=9},
  {x=33,z=-27},{x=33,z=1},{x=33,z=9},
 },
}
-- Commons rects in world space (x relative to the axis is symmetric).
do
 local a,g,c=L.axisX,L.gate,L.cross;local pw=L.promenadeWidth/2
 local function r(x0,x1,z0,z1) return {minX=a+x0,maxX=a+x1,minZ=z0,maxZ=z1} end
 local poolZ=L.southZ+40
 L.poolZ=poolZ
 L.commons={
  gatePlaza=r(-55,55,L.gatePlazaZ0,L.firstZ),
  street=r(-pw,pw,L.firstZ,poolZ-13),
  crossing=r(-pw,pw,c.z0,c.z1),
  westArm=r(-L.armReach,-pw,c.z0,c.z1),eastArm=r(pw,L.armReach,c.z0,c.z1),
  westEnd=r(-L.armReach,-L.armReach+L.endPlaza,c.z0,c.z1),eastEnd=r(L.armReach-L.endPlaza,L.armReach,c.z0,c.z1),
  southPlaza=r(-55,55,poolZ-13,poolZ+22),
 }
 L.gardens={}
 for _,z in L.stripZ do for _,side in {-1,1} do
  local x0,x1=pw,pw+L.plotDepth
  table.insert(L.gardens,if side<0 then r(-x1,-x0,z[1],z[2]) else r(x0,x1,z[1],z[2]))
 end end
end
-- Local plot offset to world x,z (rotation about +Y by yaw, as CFrame.Angles(0,yaw,0)).
function L.toWorld(i,lx,lz)
 local p=L.plots[i];local c,s=math.cos(p.yaw),math.sin(p.yaw)
 return p.x+lx*c+lz*s,p.z-lx*s+lz*c
end
function L.facing(i)
 local x,z=L.toWorld(i,0,-1);local p=L.plots[i];return x-p.x,z-p.z
end
-- World-space axis-aligned extent of a plot (yaw is always +-90 degrees).
function L.extent(i)
 local p=L.plots[i]
 return {minX=p.x-L.plotDepth/2,maxX=p.x+L.plotDepth/2,minZ=p.z-L.plotWidth/2,maxZ=p.z+L.plotWidth/2}
end
-- Basin span (v1 extents, kept): terrain berms, the gate-line exit and the sanctuary test read this.
function L.span()
 local half=L.basin.halfX
 return {minX=L.axisX-half,maxX=L.axisX+half,minZ=L.gate.z-L.gate.towerDepth/2,maxZ=L.basin.southZ}
end
-- Sanctuary area: the basin, its plots and planted margins, south of the gate.
function L.inSanctuary(x,z,north)
 local s=L.span()
 return x>s.minX-120 and x<s.maxX+120 and z>(north or L.northZ) and z<s.maxZ+120
end
function L.spawnWorld(i) return L.toWorld(i,L.contents.spawn.x,L.contents.spawn.z) end
-- Spawns look across the vertical street (same z), not at the gate.
function L.spawnLook(i) local x,z=L.spawnWorld(i);return L.axisX,z end
function L.gateDistance(i)
 local x,z=L.spawnWorld(i);return math.sqrt((x-L.gate.x)^2+(z-L.gate.z)^2)
end
return L
