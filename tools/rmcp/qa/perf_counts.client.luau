-- P3 QA (StudioAids on): HUD descendants at rest and with Shop open, plus a 10 s frame sample with Shop open.
local RS=game:GetService('RunService')
local gui=game.Players.LocalPlayer.PlayerGui:WaitForChild('MountainHUD');local probe=gui:WaitForChild('UIProbe',10)
probe:Invoke('close');task.wait(.3);local rest=#gui:GetDescendants()
local function sample(sec) local t,worst,n,over=0,0,0,0 local c=RS.Heartbeat:Connect(function(dt) t+=dt;n+=1;worst=math.max(worst,dt);if dt>1/30 then over+=1 end end)
 task.wait(sec);c:Disconnect();return {avg=math.floor(t/n*1e4)/10,worst=math.floor(worst*1e4)/10,over33=over} end
local restPerf=sample(5)
probe:Invoke('open','Shop');local shopOpen=sample(10);local shop=#gui:GetDescendants()
probe:Invoke('close')
return game:GetService('HttpService'):JSONEncode({restDescendants=rest,shopDescendants=shop,restPerf=restPerf,shopPerf=shopOpen})
