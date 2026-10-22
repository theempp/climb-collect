-- Deterministic presentation coordinates relative to the summit celebration mark.
-- No character authority or reward state lives in this timeline.
local F={}
local function ease(t,a,b) local u=math.clamp((t-a)/(b-a),0,1);return u*u*(3-2*u) end
function F.sample(t)
 local approach=ease(t,4,8);local lift=ease(t,9,11.8);local board=ease(t,11.8,13)
 local depart=math.clamp((t-13)/5,0,1);local distance=depart*depart
 return {
  x=-160+153*approach-190*distance,y=70-53*approach+70*distance,z=100-102*approach-260*distance,
  yaw=-.55*ease(t,13,15),roll=-.18*math.sin(depart*math.pi),pitch=-.1*math.sin(depart*math.pi),
  riderX=-6*board,riderY=15*lift+board,riderZ=0,
  lower=ease(t,8,9),door=ease(t,7,8)*(1-ease(t,13,13.6)),
  lift=lift,board=board,depart=depart,
 }
end
return F
