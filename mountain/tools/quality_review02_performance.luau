-- Benchmark fixture only: run with streaming disabled on an isolated unsaved copy.
local RS=game:GetService('RunService')
RS:UnbindFromRenderStep('MQPerf')
local c=workspace.CurrentCamera
settings().Rendering.QualityLevel=Enum.QualityLevel.Level10
local views={{id='whole',p=Vector3.new(4450,450,-500),t=Vector3.new(4096,190,-850)}}
for k=1,6 do local y=16+64*(k-1);local z=-210-200*(k-1);table.insert(views,{id='section-'..k,p=Vector3.new(4130,y+8,z+10),t=Vector3.new(4096,y+52,z-104)}) end
local r={streaming=workspace.StreamingEnabled,quality=tostring(settings().Rendering.QualityLevel),viewport=tostring(c.ViewportSize),parts=0,views={}}
assert(not r.streaming,'Controlled benchmark requires full residency')
for _,p in workspace.ImpossibleMountain:GetDescendants() do if p:IsA('BasePart') then r.parts+=1 end end
for _,v in views do
 c.CameraType=Enum.CameraType.Scriptable;c.CFrame=CFrame.lookAt(v.p,v.t);c.Focus=CFrame.new(v.t);c.FieldOfView=60
 task.wait(1)
 local a={};for i=1,120 do a[i]=RS.RenderStepped:Wait()*1000 end;table.sort(a)
 local render=game:GetService('SceneAnalysisService'):GetTriangleCompositionAsync()
 table.insert(r.views,{id=v.id,medianMs=a[60],p95Ms=a[114],maxMs=a[120],render=render})
end
return r
