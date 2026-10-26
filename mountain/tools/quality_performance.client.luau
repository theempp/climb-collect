local r={scope='Studio desktop simulator; stream requested at each camera; 120 RenderStepped samples; not physical-device benchmark',views={}}
local p=game.Players.LocalPlayer;local c=workspace.CurrentCamera;local svc=game:GetService('SceneAnalysisService')
local views={{id='whole-oblique',p=Vector3.new(4730,600,80),t=Vector3.new(4096,165,-750)}}
for k=1,6 do local y=16+64*(k-1);local z=-210-200*(k-1);table.insert(views,{id='section-'..k,p=Vector3.new(4002,y+80,z-110),t=Vector3.new(4125,y+67,z-176)}) end
for _,v in views do
 p:RequestStreamAroundAsync(v.t,3);c.CameraType=Enum.CameraType.Scriptable;c.CFrame=CFrame.lookAt(v.p,v.t);c.Focus=CFrame.new(v.t);c.FieldOfView=60;task.wait(.6)
 local samples={};for i=1,120 do samples[i]=game:GetService('RunService').RenderStepped:Wait()*1000 end;table.sort(samples)
 local t=svc:GetTriangleCompositionAsync();table.insert(r.views,{id=v.id,triangles=t,medianMs=samples[60],p95Ms=samples[114],maxMs=samples[120],viewport=tostring(c.ViewportSize)})
end
r.instances=svc:GetInstanceCompositionAsync();return r