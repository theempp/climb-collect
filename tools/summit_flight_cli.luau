local path='../src/core/shared/SummitFlight'
local ok,F=pcall(require,path)
assert(ok,'SummitFlight must expose the continuous pickup choreography')
for _,boundary in {4,8,9,11.8,13} do
 local a,b=F.sample(boundary-.0001),F.sample(boundary+.0001)
 for _,key in {'x','y','z','riderX','riderY','riderZ','yaw','roll','pitch','door'} do
  assert(math.abs(a[key]-b[key])<.02,'visible discontinuity at '..boundary..' '..key)
 end
end
local pickup=F.sample(11.8);assert(pickup.riderX==0 and pickup.riderY==15,'lift ends outside cabin at winch height')
local seated=F.sample(13);assert(seated.riderX==-6 and seated.riderY==16,'boarding ends in cabin before departure')
assert(F.sample(18).z < -200,'aircraft departs past summit')
print('Summit flight: continuity at five shot boundaries, lift, boarding and departure PASS')
