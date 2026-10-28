from service_harness import *
# Real EggRaids, Bats and CarryVisuals with table stand-ins for Roblox vectors and instances; no Studio or world writes.
world = r'''
local vector={}
local function v(x,y,z) return setmetatable({X=x,Y=y,Z=z},vector) end
vector.__index=function(a,key)
 if key=='Magnitude' then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
 if key=='Unit' then local m=math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z);return v(a.X/m,a.Y/m,a.Z/m) end
 if key=='Dot' then return function(self,o) return self.X*o.X+self.Y*o.Y+self.Z*o.Z end end
end
vector.__sub=function(a,b) return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vector.__add=function(a,b) return v(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vector.__mul=function(a,n) return v(a.X*n,a.Y*n,a.Z*n) end
local Vector3={new=v,zero=v(0,0,0)}
local CFrame={new=function(position) return {Position=position} end}
local created={}
local Instance={new=function(class)
 local i={ClassName=class,attributes={}}
 function i:SetAttribute(k,value) self.attributes[k]=value end
 function i:GetAttribute(k) return self.attributes[k] end
 function i:Destroy() self.destroyed=true;self.Parent=nil end
 return setmetatable(i,{__index=function(t,k) if k=='Position' then local cf=rawget(t,'CFrame');return cf and cf.Position end end,
  __newindex=function(t,k,value) rawset(t,k,value);if k=='Parent' and class=='Part' then table.insert(created,t) end end})
end}
local workspace={GetServerTimeNow=function() return 1000 end}
'''
body += world
body += '\ngame.ReplicatedStorage.MountainShared.RunRules=RunRules'
body += '\nlocal EggRaids=' + module('mountain/server/EggRaids.luau', 'local script=true')
body += '\nlocal Bats=' + module('mountain/server/Bats.luau', "local game=setmetatable({GetService=function(_,name) assert(name=='TweenService');return {} end},{__index=game})")
body += '\nlocal CarryVisuals=' + module('mountain/server/CarryVisuals.luau')
body += '\n' + (ROOT/'mountain/tests/raid_events.luau').read_text(encoding='utf-8')
with tempfile.TemporaryDirectory(prefix='raid-events-') as directory:
    target=Path(directory)/'tests.luau'
    target.write_text(body,encoding='utf8')
    subprocess.run([str(CLI),str(target)],check=True)
