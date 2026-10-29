-- Pure, shared rules; the server owns every transition and never accepts client positions/stamina.
local R = {}
function R.finite(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e12
end
function R.step(s, hand, target, now, cfg, assisted)
	if s.mode ~= "climb" and s.mode ~= "rope" then return false, "state" end
	if hand ~= "L" and hand ~= "R" then return false, "input" end
	if not R.finite(now) or now < (s.nextAt or 0) then return false, "early" end
	if not target then return false, "hold" end
	if hand ~= s.hand and not assisted then return false, "hand" end
	local cost = cfg.stepCost * (s.ice and cfg.iceCost or 1) * (s.mode == "rope" and cfg.ropeCost or 1)
	if s.stamina < cost then return false, "tired" end
	return true, cost
end
function R.canDeploy(s, now, airborne, y, launchY, cfg)
	return (s.mode == "ground" or s.mode == "fall") and airborne and s.jumpAt ~= nil and now - s.jumpAt >= 0.08
		and now - s.jumpAt <= cfg.jumpWindow and y > (s.jumpY or y) + 0.4 and launchY ~= nil
end
function R.canLand(sourceOrder, targetOrder, y, launchY)
	return type(targetOrder) == "number" and targetOrder <= sourceOrder and y <= launchY + 5
end
function R.canRemoveRope(rope, now)
	return (rope.retiring or now >= rope.expires) and (rope.occupants or 0) == 0
end
function R.checkpointAllowed(mode, grounded, route, campIndex, highestCamp)
	if mode ~= nil and mode ~= "ground" and mode ~= "none" then return false end
	if not grounded or route == "Ledge" or route == "Spire" then return false end
	return not campIndex or campIndex <= (highestCamp or 0) + 1
end
function R.movementAllowed(horizontal,upward,elapsed,approvedSpeed)
 approvedSpeed=approvedSpeed or 16
 return R.finite(horizontal) and R.finite(upward) and R.finite(elapsed) and R.finite(approvedSpeed)
  and horizontal>=0 and elapsed>=0 and approvedSpeed>=0
  and horizontal<=math.max(18,math.min(elapsed,1)*approvedSpeed*1.25+8)
  and upward<=math.max(14,math.min(elapsed,1)*20+8)
end
-- Static route segments are binned once; runtime queries only inspect the player's cell.
-- Numeric coordinates keep this geometry testable without a Roblox runtime.
function R.routeIndex(paths, padding)
	local index={bins={},cell=96,segments=0}
	padding=padding or 64
	for _,path in ipairs(paths) do
		for i=2,#path.points do
			local a,b=path.points[i-1],path.points[i]
			local dx,dy,dz=b[1]-a[1],b[2]-a[2],b[3]-a[3]
			local segment={a=a,dx=dx,dy=dy,dz=dz,length2=dx*dx+dy*dy+dz*dz,route=path.route}
			index.segments+=1
			for x=math.floor((math.min(a[1],b[1])-padding)/index.cell),math.floor((math.max(a[1],b[1])+padding)/index.cell) do
				for z=math.floor((math.min(a[3],b[3])-padding)/index.cell),math.floor((math.max(a[3],b[3])+padding)/index.cell) do
					local key=x..":"..z
					index.bins[key]=index.bins[key] or {}
					table.insert(index.bins[key],segment)
				end
			end
		end
	end
	return index
end
local function nearestRoute(index,p,radius)
	local best,route=radius*radius,nil
	local key=math.floor(p[1]/index.cell)..":"..math.floor(p[3]/index.cell)
	for _,s in ipairs(index.bins[key] or {}) do
		local x,y,z=p[1]-s.a[1],p[2]-s.a[2],p[3]-s.a[3]
		local t=s.length2>0 and math.clamp((x*s.dx+y*s.dy+z*s.dz)/s.length2,0,1) or 0
		x,y,z=x-s.dx*t,y-s.dy*t,z-s.dz*t
		local d=x*x+y*y+z*z
		if d<best then best,route=d,s.route end
	end
	return route,math.sqrt(best)
end
function R.closedRouteAt(closed,open,p)
	local route,distance=nearestRoute(closed,p,24)
	if not route then return nil end
	-- Shared crossings and nearby open trails take priority over abandoned path data.
	if nearestRoute(open,p,distance+24) then return nil end
	return route
end
R.nearestRoute=nearestRoute
function R.closedGateApproach(x,y,z)
	-- Path endpoint radii include the gate's public approach. Only its front may remain open.
	return math.abs(x)<=24 and y>=-6 and y<=12 and z>=0 and z<=32
end
return R
