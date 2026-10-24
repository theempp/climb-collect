-- Disposable camera-only fixture. Never saves or grants player progression/position.
local Run=game:GetService('RunService')
local camera=workspace.CurrentCamera;local previous=camera.CameraType
local records={};local world=workspace.ImpossibleMountain
camera.CameraType=Enum.CameraType.Scriptable
local target=world.Encounters.Guardian_1.PrimaryPart.Position
Run:BindToRenderStep('MountainQA_ArtCamera',Enum.RenderPriority.Camera.Value+1,function() camera.CFrame=CFrame.lookAt(target+Vector3.new(22,12,-38),target) end)
for i=1,6 do
 local model=world.Encounters['Guardian_'..i];target=model.PrimaryPart.Position
 task.wait(.2)
 local rootStart=model.PrimaryPart.CFrame;local poses={}
 for _,p in ipairs(model:GetChildren()) do if p:IsA('BasePart') and p:GetAttribute('MotionRole') then poses[p]=model.PrimaryPart.CFrame:ToObjectSpace(p.CFrame) end end
 task.wait(.65)
 local changed=0
 for p,cf in pairs(poses) do
  local current=model.PrimaryPart.CFrame:ToObjectSpace(p.CFrame)
  if (current.Position-cf.Position).Magnitude>.005 or current.LookVector:Dot(cf.LookVector)<.99999 then changed+=1 end
 end
 table.insert(records,{guardian=i,articulatedParts=changed,rootStationary=model.PrimaryPart.CFrame==rootStart,passed=changed>0 and model.PrimaryPart.CFrame==rootStart})
end
Run:UnbindFromRenderStep('MountainQA_ArtCamera');camera.CameraType=previous
workspace:SetAttribute('MountainQA_ArtMotion',game.HttpService:JSONEncode({scope='camera-only animation fixture; no player progression grants',records=records}))
