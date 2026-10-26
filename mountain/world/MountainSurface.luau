-- Shared, deterministic surface contract. Heights are local to each existing tier.
local S={version=1}
S.widths={-172,-120,-72,-16,16,72,120,172}
S.depths={0,20,40,60,80,100,120}
local profiles={
 {0,16,32,38,42,50,64},
 {0,8,24,40,46,50,64},
 {0,16,28,36,38,48,64},
 {0,16,32,38,40,48,64},
 {0,8,16,32,48,56,64},
 {0,16,28,34,48,56,64},
}
function S.height(k,x,depth)
 local d=math.clamp(depth,0,120);local base=64*d/120
 local a=math.abs(x);local weight=math.clamp(math.min((a-16)/88,(172-a)/52),0,1)
 local profile=profiles[if x<0 then k else k%6+1]
 local segment=math.min(6,math.floor(d/20)+1);local t=(d-(segment-1)*20)/20
 return base+(profile[segment]*(1-t)+profile[segment+1]*t-base)*weight
end
function S.sandstoneRecovery()
 -- A static ramp at the rear of the catch, outside the moving TellArt contract.
 return {{x=4168,y=202,z=-764},{x=4168,y=208,z=-775}}
end
return S
