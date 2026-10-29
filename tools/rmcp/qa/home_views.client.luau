-- P0 baseline (Play Solo, Client): camera at each home spawn (eye +6) looking at the mountain through the gate,
-- 120 RenderStepped frames per view; draw calls/triangles from Stats when exposed. Same method as performance-eight-homes.json.
local RS=game:GetService('RunService');local St=game:GetService('Stats')
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local cam=workspace.CurrentCamera;local prevType=cam.CameraType;cam.CameraType=Enum.CameraType.Scriptable;cam.FieldOfView=70
local function stat(names) for _,n in names do local ok,v=pcall(function() return St[n] end) if ok and type(v)=='number' then return v end end end
local views={}
for i=1,8 do
 local x,z=L.spawnWorld(i);cam.CFrame=CFrame.lookAt(Vector3.new(x,L.groundY+6,z),Vector3.new(4096,240,-820));task.wait(1.5)
 local ts={};local c=RS.RenderStepped:Connect(function(dt) table.insert(ts,dt*1000) end)
 repeat task.wait() until #ts>=120;c:Disconnect();table.sort(ts)
 table.insert(views,{home=i,medianMs=math.floor(ts[60]*10+.5)/10,p95Ms=math.floor(ts[114]*10+.5)/10,worstMs=math.floor(ts[#ts]*10+.5)/10,
  drawcalls=stat({'SceneDrawcallCount','DrawCallCount'}),triangles=stat({'SceneTriangleCount','TriangleCount'}),gpuMs=stat({'RenderGPUFrameTime'}),cpuMs=stat({'RenderCPUFrameTime'})})
end
cam.CameraType=prevType
local inst=0 for _ in workspace:GetDescendants() do inst+=1 end
local plots={} for _,pl in workspace.Sanctuary.SanctuaryPlots:GetChildren() do plots[pl.Name]=#pl:GetDescendants() end
return game:GetService('HttpService'):JSONEncode({views=views,workspaceDescendants=inst,plotRuntime=plots,memoryMB=math.floor(St:GetTotalMemoryUsageMb())})
