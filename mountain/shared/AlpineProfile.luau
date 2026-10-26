-- Pure spatial contract for cosmetic mountain presentation. No gameplay state.
local P={version=1}
local G=if game then require(game.ReplicatedStorage.MountainShared.CompactGeometry) else require('./CompactGeometry')
local function smooth(a,b,x)
 local t=math.clamp((x-a)/(b-a),0,1);return t*t*(3-2*t)
end
P.smooth=smooth
function P.intensity(x,y,z)
 local p=G.original({x=x,y=y,z=z});x=p.x;y=p.y;z=p.z
 local area=(1-smooth(210,360,math.abs(x-4096)))*smooth(-210,-270,z)*(1-smooth(1410,1510,-z))
 return smooth(16,400,y)*area
end
local colors={{96,125,91},{99,128,119},{151,135,105},{116,119,134},{96,105,117},{179,194,207}}
function P.ground(x,z)
 -- Boundaries wander across the face; the same palette continues onto shoulders.
 local depth=-210-z+42*math.sin(x*.014+z*.009)+22*math.noise(x*.009,z*.011,31)
 local v=math.clamp((depth-90)/200+1,1,6);local k=math.min(5,math.floor(v))
 local t=smooth(0,1,v-k);local a,b=colors[k],colors[k+1]
 local grain=math.noise(x*.023,z*.019,7)*9
 return {a[1]+(b[1]-a[1])*t+grain,a[2]+(b[2]-a[2])*t+grain,a[3]+(b[3]-a[3])*t+grain}
end
return P
