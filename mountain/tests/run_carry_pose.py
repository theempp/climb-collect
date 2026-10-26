"""Run the real pose callback for both current and legacy avatar joint types."""
from service_harness import module, CLI
from pathlib import Path
import subprocess,tempfile
body=r'''
local callback
local Run={PreSimulation={Connect=function(_,fn) callback=fn end}}
local CFrame={Angles=function(x,y,z) return {x=x,y=y,z=z} end}
local joints={}
for _,class in ipairs({'Motor6D','AnimationConstraint'}) do
 for _,name in ipairs({'LeftShoulder','RightShoulder','LeftElbow','RightElbow'}) do
  local joint={Name=name,ClassName=class}
  function joint:IsA(v) return v==self.ClassName end
  table.insert(joints,joint)
 end
end
local c={GetAttribute=function(_,k) return if k=='CarryingCreature' then true else nil end,GetDescendants=function() return joints end}
local Players={GetPlayers=function() return {{Character=c}} end}
local game={GetService=function(_,k) return if k=='Players' then Players else Run end}
local workspace={GetServerTimeNow=function() return 0 end}
'''
body+='\n'+module('mountain/client/EggCarry.client.luau')+'\ncallback()\n'
body+=r'''
local checks=0
for _,j in ipairs(joints) do
 assert(j.Transform and j.Transform.x>0,'carry pose missing on '..j.ClassName..' '..j.Name);checks+=1
end
print('PASS '..checks..' legacy/current carry joint checks')
'''
with tempfile.TemporaryDirectory(prefix='carry-pose-') as directory:
 target=Path(directory)/'test.luau';target.write_text(body,encoding='utf8')
 subprocess.run([str(CLI),str(target)],check=True)
