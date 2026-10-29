-- SummitFlight (src/core/shared) headless checks: start pose, settled tail, 0..1 phases, door open/close, determinism. Pure math, no Roblox.
local F=require('../../src/core/shared/SummitFlight')
local n=0;local function check(v,name) assert(v,name);n+=1 end
local EPS=1e-9
local function count(t) local c=0;for _ in pairs(t) do c+=1 end;return c end
-- Start pose.
local s0=F.sample(0)
check(s0.x==-160 and s0.y==70 and s0.z==100,string.format('sample(0) = %g,%g,%g, want -160,70,100',s0.x,s0.y,s0.z))
-- Settled tail: nothing changes from t=18 on.
local ref=F.sample(18)
for _,t in ipairs({18,18.5,19,20,25,60,1000}) do
 local s=F.sample(t)
 check(count(s)==count(ref),'field count differs at t='..t)
 for k,v in pairs(ref) do check(s[k]~=nil and math.abs(s[k]-v)<=EPS,'field '..k..' drifts at t='..t) end
end
-- Phases stay in 0..1, door opens then closes (grid 0..20 step 0.01).
local lo,hi={lift=1,board=1,depart=1},{lift=0,board=0,depart=0}
local peak,peakT,prev=-1,0,nil
for i=0,2000 do
 local t=i/100;local s=F.sample(t)
 for k in pairs(lo) do lo[k]=math.min(lo[k],s[k]);hi[k]=math.max(hi[k],s[k]) end
 if s.door>peak then peak,peakT=s.door,t end
 if t<=7 or t>=13.6 then check(math.abs(s.door)<=EPS,'door not closed at t='..t) end
 if prev then
  if t<=13 then check(s.door>=prev-EPS,'door falls before t=13 at t='..t) end
  if t>=13 then check(s.door<=prev+EPS,'door rises after t=13 at t='..t) end
 end
 prev=s.door
end
for k in pairs(lo) do check(lo[k]>=0 and hi[k]<=1,string.format('%s out of 0..1 (min %g max %g)',k,lo[k],hi[k])) end
check(peak>=1-EPS and peakT>=8 and peakT<=13,string.format('door peak %g at t=%g, want 1 within 8..13',peak,peakT))
check(math.abs(F.sample(13.6).door)<=1e-6,'door not closed at t=13.6')
-- Determinism: same t, same output, fresh tables.
for _,t in ipairs({0,3.3,7.5,11.8,13,13.3,15,17.99,18,20}) do
 local a,b=F.sample(t),F.sample(t)
 check(not rawequal(a,b),'sample returns a shared table at t='..t)
 check(count(a)==count(b),'field count differs between calls at t='..t)
 for k,v in pairs(a) do check(b[k]==v,'field '..k..' differs between calls at t='..t) end
end
print(string.format('PASS %d summit flight checks (door peak %.3f at t=%.2f, depart(20)=%g)',n,peak,peakT,F.sample(20).depart))
