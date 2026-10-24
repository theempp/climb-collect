local T={}
function T.gravityScale(x,y,z,halfX,halfZ)
 if math.abs(x)<=halfX and math.abs(z)<=halfZ and y>=0 and y<=30 then return .38 end
 return 1
end
function T.sandSpeed(time) return math.sin(time*math.pi/6)*5 end
return T
