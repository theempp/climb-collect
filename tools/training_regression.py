"""Run the real Training module with isolated Luau scheduling/transaction doubles."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "src/core/server/Training.luau").read_text(encoding="utf-8")
HARNESS = r'''
local moduleSource = [====[__TRAINING_SOURCE__]====]
local function fixture()
 local jobs, listeners, pending = {}, {}, nil
 local position=setmetatable({}, {__sub=function() return {Magnitude=0} end})
 local gate={Position=position}
 local yard={FindFirstChild=function() return gate end}
 local plr={UserId=42,Parent=true,Character={FindFirstChild=function() return {Position=position} end}}
 local s={data={gear={training={unlocked={['2']=true},completed={}}},coins=100}}
 local calls,good,dress=0,0,0
 local mode='success'
 local ctx={sessions={[plr]=s},handlers={},C={PRACTICE={costs={0,25,60},labels={'one','two','three'},gains={10,10,20},staminaCap=140}}}
 ctx.on=function(name,fn) listeners[name]=fn end
 ctx.toast=function(_,_,kind) if kind=='good' then good+=1 end end
 ctx.push=function() end ctx.fx=function() end
 ctx.Gear={dress=function() dress+=1 end,trainingBonus=function() return 0 end}
 ctx.transaction=function(_,_,transform,committed)
  if s.saving or s.pending or s.busy or s.outcomePending then return {ok=false,reason='busy'} end
  calls+=1
  local candidate={gear={training={unlocked=s.data.gear.training.unlocked,completed=table.clone(s.data.gear.training.completed)}},coins=s.data.coins}
  local r=transform(candidate)
  if r.ok==false then return r end
  if mode=='duplicate' then r.dup=true end
  if mode=='uncertain' then pending={candidate=candidate,result=r,callback=committed}; s.pending=true; return {ok=false,pending=true} end
  s.data=candidate committed(r) return r
 end
 local env=setmetatable({
  game={GetService=function() return {GenerateGUID=function() return 'test-guid' end} end},
  workspace={World={FindFirstChild=function(_,name) return name=='TrainingYard' and yard or nil end}},
  script={Parent={Prompts={}}},
  require=function() return {make=function() return {Triggered={Connect=function() end}} end,validate=function() return true end} end,
  task={spawn=function(fn) local co=coroutine.create(fn); jobs[#jobs+1]=co; assert(coroutine.resume(co)); return co end,wait=function() coroutine.yield() end},
 },{__index=getfenv(0)})
 local chunk=assert(loadstring(moduleSource)); setfenv(chunk,env)
 local training=chunk(); training.init(ctx)
 return {
  session=s,player=plr,
  start=function(id) ctx.handlers.practiceStart(plr,{id=id or 1}) end,
  section=function(id) listeners.traversalSection(plr,id or 'Practice:1') end,
  tick=function() for _,co in ipairs(jobs) do if coroutine.status(co)~='dead' then assert(coroutine.resume(co)) end end end,
  counts=function() return calls,good,dress end,
  mode=function(value) mode=value end,
  confirm=function() assert(pending); s.data=pending.candidate; s.pending=nil; pending.callback(pending.result) end,
  leave=function() training.onLeave(plr);ctx.sessions[plr]=nil end,
 }
end
local passed=0
local function test(name,fn) fn(); passed+=1;print('PASS '..name) end
test('validated completion survives autosave and cannot be overwritten',function()
 local f=fixture();f.start();f.session.saving=true;f.section();f.start(2)
 assert(not f.session.data.gear.training.completed['1'],'acknowledged while busy')
 f.session.saving=false;f.tick()
 assert(f.session.data.gear.training.completed['1'],'validated finish discarded during save')
 assert(not f.session.data.gear.training.completed['2'],'new lesson replaced queued finish')
 local calls,good=f.counts();assert(calls==1 and good==1);f.tick();assert(f.counts()==1)
end)
test('uncertain completion waits for durable callback and acknowledges once',function()
 local f=fixture();f.mode('uncertain');f.start();f.section();f.tick();f.tick()
 local calls,good=f.counts();assert(calls==1 and good==0,'pending result acknowledged or resubmitted')
 f.confirm();f.confirm();f.tick()
 calls,good=f.counts();assert(calls==1 and good==1,'duplicate callback repeated success')
 assert(f.session.data.gear.training.completed['1'])
end)
test('receipt replay does not repeat reward feedback',function()
 local f=fixture();f.mode('duplicate');f.session.data.gear.training.completed['1']=true;f.start();f.section();f.tick()
 local calls,good=f.counts();assert(calls==1 and good==0,'receipt replay repeated success toast')
end)
test('wrong wall and departed player cannot complete queued lesson',function()
 local f=fixture();f.start();f.section('Practice:2');assert(f.counts()==0)
 f.session.saving=true;f.section();f.leave();f.session.saving=false;f.tick();assert(f.counts()==0)
end)
print('Training queue: '..passed..'/'..passed..' passed (real module, isolated scheduler)')
'''
with tempfile.TemporaryDirectory(prefix="cc-training-") as temp:
    harness = Path(temp) / "training.luau"
    harness.write_text(HARNESS.replace("__TRAINING_SOURCE__", SOURCE), encoding="utf-8")
    result = subprocess.run([str(ROOT / "tools/.luau/luau.exe"), str(harness)], cwd=ROOT)
    raise SystemExit(result.returncode)
