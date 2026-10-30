-- polish_motion.client.luau : HUD polish P3. Frame times over 10 card expand/collapse toggles, mid-tween rect sample, loops at rest after.
local gui=game.Players.LocalPlayer.PlayerGui.MountainHUD;local pr=gui.UIProbe;local RS=game:GetService('RunService')
local card=gui:FindFirstChild('PlayerCard',true)
pr:Invoke('close');pr:Invoke('hudState','sanctuary');task.wait(1)
local dts,worst,over33={},0,0;local c=RS.RenderStepped:Connect(function(dt) table.insert(dts,dt*1000) end)
local mid
for i=1,10 do
	pr:Invoke('card',i%2==1 and 'expanded' or 'compact')
	task.wait(.1);if i==1 then mid={math.floor(card.AbsolutePosition.Y),math.floor(card.AbsoluteSize.Y)} end
	task.wait(.3)
end
c:Disconnect()
local sum=0;for _,d in ipairs(dts) do sum+=d;worst=math.max(worst,d);if d>33 then over33+=1 end end
local stats=pr:Invoke('motionStats')
pr:Invoke('hudState','live')
return game:GetService('HttpService'):JSONEncode({frames=#dts,avg=math.floor(sum/#dts*10)/10,worst=math.floor(worst*10)/10,over33=over33,midExpand=mid,final={math.floor(card.AbsolutePosition.Y),math.floor(card.AbsoluteSize.Y)},motionStats=stats})
