local R=require("../src/core/shared/TraversalRules")
assert(type(R.routeIndex)=="function","closed-route access index is missing")
local closed=R.routeIndex({{route="Ledge",points={{120,0,0},{120,0,-600},{300,0,-600}}}},64)
local open=R.routeIndex({{route="Shepherd",points={{0,0,0},{0,0,-600}}},{route="shared",points={{0,0,-400},{180,0,-400}}}},64)
local n=0
local function check(name,fn) assert(fn(),name); n+=1 end
check("deep entrant is rejected beyond entrance box",function() return R.closedRouteAt(closed,open,{120,3,-550})=="Ledge" end)
check("side entrant is rejected on closed lane",function() return R.closedRouteAt(closed,open,{137,3,-550})=="Ledge" end)
check("closed route bend is protected",function() return R.closedRouteAt(closed,open,{290,3,-600})=="Ledge" end)
check("shared crossing remains open",function() return R.closedRouteAt(closed,open,{120,3,-400})==nil end)
check("open route remains open",function() return R.closedRouteAt(closed,open,{0,3,-550})==nil end)
check("stacked open ledge remains open",function() return R.closedRouteAt(closed,open,{120,70,-550})==nil end)
check("unrelated terrain stays free",function() return R.closedRouteAt(closed,open,{200,3,-500})==nil end)
check("negative cell boundary resolves segments",function()
 local idx=R.routeIndex({{route="Spire",points={{-200,10,-200},{-64,10,-64}}}},64)
 return R.closedRouteAt(idx,R.routeIndex({},64),{-64,13,-64})=="Spire"
end)
check("gate return point has a bounded front approach",function() return R.closedGateApproach and R.closedGateApproach(0,3,16) end)
check("gate front exemption never extends behind or around gate",function()
 return not R.closedGateApproach(0,3,-1) and not R.closedGateApproach(25,3,16)
  and not R.closedGateApproach(0,3,33) and not R.closedGateApproach(0,13,16)
end)
check("built public deck keeps its crossing open while closed trail continues guarded",function()
 local repaired=R.routeIndex({{route="Shepherd",points={{90,0,-550},{150,0,-550}}}},64)
 return R.closedRouteAt(closed,repaired,{120,3,-550})==nil
  and R.closedRouteAt(closed,repaired,{120,3,-480})=="Ledge"
end)
print("Traversal route access: "..n.."/"..n.." passed")
