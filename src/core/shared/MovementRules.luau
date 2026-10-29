-- Pure policy; callers retain ownership of character state and the sole stamina pool.
local R={}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<1e12 end
function R.step(intent,s,dt,c)
 dt=finite(dt) and math.clamp(dt,0,0.2) or 0
 local maximum=finite(s.maxStamina) and math.max(0,s.maxStamina) or 100
 local stamina=finite(s.stamina) and math.clamp(s.stamina,0,maximum) or 0
 local out={requested=intent.requested==true,exhausted=intent.exhausted==true,sprinting=false,walkSpeed=0,stamina=stamina}
 if out.exhausted and stamina>=c.restartStamina then out.exhausted=false end
 if not s.alive or s.locked then out.requested=false;return out end
 if s.mode~='ground' and s.mode~='fall' then out.requested=false;return out end
 out.walkSpeed=c.walkSpeed
 if not s.grounded or s.mode=='fall' then
  -- No drain or recovery in air. Only a short contact loss keeps intent and pace.
  local brief=finite(s.airborneFor) and s.airborneFor<=c.airGrace
  if s.zone=='lobby' then out.requested=false;out.walkSpeed=c.lobbySpeed
  elseif not brief or s.zone~='mountain' or out.exhausted then out.requested=false
  elseif out.requested then out.walkSpeed=c.sprintSpeed end
  return out
 end
 if s.zone=='lobby' then out.requested=false;out.walkSpeed=c.lobbySpeed
 elseif s.zone=='home' then out.requested=false end
 if out.exhausted then out.requested=false end
 if out.requested and s.zone=='mountain' and s.moving then
  out.stamina=math.max(0,stamina-c.sprintDrain*dt)
  if out.stamina<=0 then out.requested=false;out.exhausted=true
  else out.sprinting=true;out.walkSpeed=c.sprintSpeed end
 else out.stamina=math.min(maximum,stamina+c.groundRegen*dt) end
 return out
end
function R.advanceBudget(credit,elapsed,speed,distance,c)
 if not finite(credit) or not finite(elapsed) or not finite(speed) or not finite(distance)
  or credit<0 or elapsed<0 or speed<0 or distance<0 then return 0,false end
 local available=math.min(c.distanceBurst,credit+elapsed*speed*c.distanceSlack)
 if distance>available then return credit,false end
 return available-distance,true
end
return R
