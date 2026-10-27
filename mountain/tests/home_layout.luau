local L=require('../shared/HomeLayout')
local n=0
local function check(v,label) n+=1;assert(v,label) end
local function close(a,b) return math.abs(a-b)<1e-6 end
local function overlap(a,b,gap) return a.minX<b.maxX+gap and b.minX<a.maxX+gap and a.minZ<b.maxZ+gap and b.minZ<a.maxZ+gap end
check(#L.plots==8,'eight homes')
local west,east=0,0
for i,p in L.plots do
 if p.side<0 then west+=1 else east+=1 end
 -- Facing: each home's front points across the promenade at the avenue axis.
 local fx,fz=L.facing(i);check(close(fz,0) and close(fx,-p.side),'faces promenade '..i)
 local e=L.extent(i)
 check(close(e.maxX-e.minX,180) and close(e.maxZ-e.minZ,140),'140x180 footprint '..i)
 -- Plot edge sits exactly on the promenade edge.
 local inner=if p.side<0 then e.maxX else e.minX
 check(close(math.abs(inner-L.axisX),L.promenadeWidth/2),'promenade edge '..i)
 -- The gate is north of every home with clearance for its towers.
 check(e.minZ>=L.gate.z+L.gate.towerDepth/2+4,'gate clearance '..i)
 check(L.inSanctuary(p.x,p.z),'home inside sanctuary '..i)
 for j=i+1,8 do check(not overlap(e,L.extent(j),L.buffer-1e-6),'no overlap/buffer '..i..':'..j) end
 -- Spacing along each side.
 if i>2 then local q=L.plots[i-2];check(q.side==p.side and close(p.z-q.z,L.rowPitch),'row spacing '..i) end
 -- Spawn faces out onto the promenade and the walk to the gate beats the old row.
 local d=L.gateDistance(i);check(d<L.previousFarthestWalk and d<=560,'gate distance '..i..' '..d)
end
check(west==4 and east==4,'4 west, 4 east')
check(close(L.southZ-L.firstZ,4*L.plotWidth+3*L.buffer),'side length 584 (plan ~592 incl. end buffer)')
-- Promenade lanes: two walking lanes either side of the decorative channel.
check(close(L.channelWidth+2*L.laneWidth,L.promenadeWidth),'channel+lanes fill promenade')
check(2*L.laneWidth>=L.escapeWidth,'return walking width')
check(L.gate.opening>=L.promenadeWidth,'gate opening spans promenade')
check(not L.inSanctuary(L.axisX,L.gate.z-20) and L.inSanctuary(L.axisX,L.gate.z+12),'gate is the sanctuary boundary')
check(not L.inSanctuary(L.axisX,-210),'mountain entrance outside sanctuary')
-- Contents fit inside the 140x180 plot with clearance and do not overlap.
local c=L.contents;local hw,hd=L.plotWidth/2,L.plotDepth/2
local function box(x,z,w,d) return {minX=x-w/2,maxX=x+w/2,minZ=z-d/2,maxZ=z+d/2} end
local rects={
 tycoon={minX=-c.tycoonHalfX,maxX=c.tycoonHalfX,minZ=c.tycoonZ+c.tycoonMinZ,maxZ=c.tycoonZ+c.tycoonMaxZ},
 spawn=box(c.spawn.x,c.spawn.z,c.spawn.size,c.spawn.size),
 lodge={minX=c.lodge.x-c.lodge.width/2,maxX=c.lodge.x+c.lodge.width/2,minZ=c.lodge.z-c.lodge.depth/2,maxZ=c.lodge.z+c.lodge.depth/2+c.lodge.overhang},
}
for _,s in c.services do rects[s.kind]=box(s.x,s.z,s.size,s.size) end
for name,r in rects do check(r.minX>=-hw+2 and r.maxX<=hw-2 and r.minZ>=-hd+2 and r.maxZ<=hd-2,'fits plot '..name) end
for a,ra in rects do for b,rb in rects do if a<b then check(not overlap(ra,rb,3),'content clearance '..a..':'..b) end end end
print(string.format('PASS %d home layout checks (farthest spawn-to-gate %.0f studs)',n,math.max(table.unpack((function() local t={} for i=1,8 do t[i]=L.gateDistance(i) end return t end)()))))
