-- Home-base promenade, approved 2026-10-26: 4 homes per side of a garden promenade, one gate at the mountain end.
-- Pure numbers (no Roblox types) so CLI tests and the server read the same layout.
-- Plot local frame: X along the avenue (140), Z = depth (180), front edge at local z=-90 faces the promenade.
local L={version=1,axisX=4096,groundY=16,plotWidth=140,plotDepth=180,buffer=8,
 promenadeWidth=70,channelWidth=12,laneWidth=29,escapeWidth=32,firstZ=-148,floorName='Plot_140x180',
 -- The gate stands on the existing center sanctuary exit line (z -166); north of z -157 is mountain.
 gate={x=4096,z=-166,opening=150,towerWidth=26,towerDepth=24,height=72},northZ=-157,
 -- Old row: farthest spawn walked ~722 studs to its gate (Review02 frontage path).
 previousFarthestWalk=722,
 contents={
  tycoonZ=-16,tycoonHalfX=48.5,tycoonMinZ=-54.5,tycoonMaxZ=60,
  spawn={x=0,z=-83,size=6},
  services={{kind='Incubator',x=-14,z=-83,size=3},{kind='Training',x=14,z=-83,size=3}},
  lodge={x=0,z=64,width=35,depth=30,overhang=5.75},
 },
}
L.rowPitch=L.plotWidth+L.buffer
L.southZ=L.firstZ+4*L.rowPitch-L.buffer
L.plots={}
for i=1,8 do
 -- Odd slots west, even east; slot 1-2 nearest the gate so the first players are closest.
 local side=if i%2==1 then -1 else 1
 local row=math.ceil(i/2)
 local yaw=if side<0 then -math.pi/2 else math.pi/2
 L.plots[i]={index=i,side=side,row=row,yaw=yaw,
  x=L.axisX+side*(L.promenadeWidth/2+L.plotDepth/2),
  z=L.firstZ+(row-1)*L.rowPitch+L.plotWidth/2}
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
function L.span()
 local half=L.promenadeWidth/2+L.plotDepth
 return {minX=L.axisX-half,maxX=L.axisX+half,minZ=L.gate.z-L.gate.towerDepth/2,maxZ=L.southZ}
end
-- Sanctuary area: the avenue, its plots and planted margins, south of the gate.
function L.inSanctuary(x,z,north)
 local s=L.span()
 return x>s.minX-120 and x<s.maxX+120 and z>(north or L.northZ) and z<s.maxZ+120
end
function L.spawnWorld(i) return L.toWorld(i,L.contents.spawn.x,L.contents.spawn.z) end
function L.gateDistance(i)
 local x,z=L.spawnWorld(i);return math.sqrt((x-L.gate.x)^2+(z-L.gate.z)^2)
end
return L
