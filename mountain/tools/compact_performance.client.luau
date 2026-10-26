local R={done=false,scope='Studio desktop, full residency; camera probes do not move avatar',views={}}
_G.CompactPerformance=R
local function publish() workspace:SetAttribute('MountainQA_CompactPerformance',game.HttpService:JSONEncode(R)) end
task.spawn(function()
 local svc=game:GetService('SceneAnalysisService');local cam=workspace.CurrentCamera
 local oldType,oldCF,oldFocus,oldFov=cam.CameraType,cam.CFrame,cam.Focus,cam.FieldOfView
 cam.CameraType=Enum.CameraType.Scriptable;cam.FieldOfView=70
 local view
 local run=game:GetService('RunService')
 run:BindToRenderStep('CompactPerformanceCamera',Enum.RenderPriority.Camera.Value+1,function() if view then cam=workspace.CurrentCamera;cam.CameraType=Enum.CameraType.Scriptable;cam.CFrame=view;cam.Focus=CFrame.new(4096,240,-820);cam.FieldOfView=70 end end)
 for i=1,8 do
  view=CFrame.lookAt(Vector3.new(3438+(i-1)*188,8,176),Vector3.new(4096,240,-820))
  task.wait(2);local samples={}
  for k=1,120 do samples[k]=game:GetService('RunService').RenderStepped:Wait()*1000 end
  table.sort(samples)
  local n=0;for _,p in workspace.ImpossibleMountain:GetDescendants() do if p:IsA('BasePart') then n+=1 end end
  local ok,triangles=pcall(function() return svc:GetTriangleCompositionAsync() end)
  table.insert(R.views,{home=i,camera={cam.CFrame:GetComponents()},cameraError=(cam.CFrame.Position-view.Position).Magnitude,parts=n,medianMs=samples[60],p95Ms=samples[114],memoryMB=game.Stats:GetTotalMemoryUsageMb(),viewport=tostring(cam.ViewportSize),triangles=ok and triangles or tostring(triangles)})
  publish()
 end
 run:UnbindFromRenderStep('CompactPerformanceCamera');cam.CameraType=oldType;cam.CFrame=oldCF;cam.Focus=oldFocus;cam.FieldOfView=oldFov;R.done=true;publish()
end)
return 'Eight home sightline/performance probes started; no streaming requests'
