-- Run in Client, never Edit. Streaming requested per view; not a hardware benchmark.
assert(game:GetService('RunService'):IsClient(),'Client performance fixture only')
task.spawn(function()
 local Run=game:GetService('RunService');local camera=workspace.CurrentCamera
 local prior={kind=camera.CameraType,cf=camera.CFrame,focus=camera.Focus,fov=camera.FieldOfView}
 local frame
 local ok,result=pcall(function()
  local r={scope='Studio Client; streaming requested at each view; effects depend on actual character altitude; 120 frames each; no hardware/FPS claim',views={}}
  local views={{id='whole',p=Vector3.new(4450,450,-500),t=Vector3.new(4096,190,-850)}}
  for k=1,6 do local y=16+64*(k-1);local z=-210-200*(k-1);table.insert(views,{id='section-'..k,p=Vector3.new(4130,y+8,z+10),t=Vector3.new(4096,y+52,z-104)}) end
  local active
  frame=Run.RenderStepped:Connect(function()if active then camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.lookAt(active.p,active.t);camera.Focus=CFrame.new(active.t);camera.FieldOfView=60 end end)
  for _,v in views do
   game.Players.LocalPlayer:RequestStreamAroundAsync(v.t,3);active=v;task.wait(1)
   local a={};for i=1,120 do a[i]=Run.RenderStepped:Wait()*1000 end;table.sort(a)
   local render=game:GetService('SceneAnalysisService'):GetTriangleCompositionAsync()
   table.insert(r.views,{id=v.id,medianMs=a[60],p95Ms=a[114],maxMs=a[120],render=render,viewport=tostring(camera.ViewportSize),effect=workspace.LocalAltitudeAtmosphere:GetAttribute('Intensity')})
  end
  return r
 end)
 if frame then frame:Disconnect() end
 camera.CameraType=prior.kind;camera.CFrame=prior.cf;camera.Focus=prior.focus;camera.FieldOfView=prior.fov
 _G.REVIEW06_RENDER={ok=ok,data=result}
end)
return 'Play-mode rendering measurement started'
