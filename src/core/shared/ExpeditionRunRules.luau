-- Pure, bounded ascent evidence. Only server observations enter this reducer.
local R={}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
function R.default() return {nextSeq=1,completedThrough=0,returnedThrough=0,retiredThrough=0,acknowledgedSeq=0} end
function R.begin(seq,route,now)
 if not table.find({'Shepherd','Waterfall'},route) or not finite(now) then return nil end
 return {seq=seq,id='ascent:'..seq,startedAt=now,lastObservedAt=now,phase='ascending',startRoute=route,currentRoute=route,mixedRoute=false,lastMilestone=0,routeEvidence={band=0,distance=0,sections=0},findTotals={creatures=0,heartstones=0},newBankedSpecies=0}
end
function R.reduce(a,e,c)
 if not a or a.invalid or a.phase~='ascending' then return end
 if not finite(e.at) or e.at<a.lastObservedAt then a.invalid='clock';return end
 a.lastObservedAt=e.at
 local r=a.routeEvidence
 if e.kind=='travel' then
  -- All transports reset continuity; only explicitly whitelisted non-ascent travel preserves the run.
  if not table.find({'homeEnter','homeReturn','reconnect','respawn','fall','climbLanding','parachute'},e.travel) then a.invalid='transport' end
 elseif e.kind=='sample' then
  if not e.valid then a.invalid='movement';return end
  if not finite(e.y) or not finite(e.distance) then a.invalid='nonfinite';return end
  if e.nearRoute and e.progressAllowed then
   local band=math.max(0,math.floor((e.y-48)/c.bandHeight))
   if band==r.band+1 then r.band=band end
   r.distance+=math.max(0,math.min(e.distance,30))
  elseif e.nearRoute and e.progressAllowed==nil then -- pure rule callers default to a walking observation
   local band=math.max(0,math.floor((e.y-48)/c.bandHeight));if band==r.band+1 then r.band=band end
   r.distance+=math.max(0,e.distance)
  end
 elseif e.kind=='camp' and e.index==a.lastMilestone+1 then
  a.lastMilestone=e.index
 elseif e.kind=='section' and e.route~='Practice' and e.route~='Ledge' and e.route~='Spire' then
  if r.lastSection~=e.id then r.sections+=1;r.lastSection=e.id end
  if table.find({'Shepherd','Waterfall'},e.route) and e.route~=a.currentRoute then a.currentRoute=e.route;a.mixedRoute=true end
 elseif e.kind=='merge' and a.lastMilestone==4 then a.merge=true
 end
end
function R.eligible(a,arrival,c)
 if not a then return {ok=false,reason='noDeparture'} end
 local reason=a.invalid
 if not reason and (not finite(arrival.at) or arrival.at<a.startedAt) then reason='clock' end
 if not reason and not arrival.grounded then reason='unsafeArrival' end
 if not reason and (a.lastMilestone<c.requiredCamps or a.routeEvidence.band<(c.requiredBand or 31) or a.routeEvidence.sections<1 or a.routeEvidence.distance<(c.minimumDistance or 0) or (c.requireMerge and not a.merge)) then reason='incompleteAscent' end
 if not reason and arrival.at-a.startedAt<c.minimumSeconds then reason='tooFast' end
 return {ok=reason==nil,reason=reason,run=a}
end
return R
