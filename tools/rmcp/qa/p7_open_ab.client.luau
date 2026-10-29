-- P7 Shop open A/B (same session): 6 opens with motion and 6 with Reduce effects (UIProbe motionPrefs), interleaved. Per open:
-- the frame times of the first 1.2 s after open; reports mean worst, mean 2nd worst and max per mode. Gate (plan §4 P6): motion
-- within +1 ms of reduced.
local gui=game.Players.LocalPlayer.PlayerGui.MountainHUD;local pr=gui.UIProbe;local RS=game:GetService('RunService')
local res={normal={},reduced={}}
for i=1,12 do
 local mode=if i%2==1 then 'normal' else 'reduced'
 pr:Invoke('motionPrefs',if mode=='reduced' then {reducedMotion=true,simplifiedVFX=true} else nil)
 pr:Invoke('close');task.wait(.8)
 local ft={};local c=RS.RenderStepped:Connect(function(dt) table.insert(ft,dt*1000) end)
 pr:Invoke('open','Shop');task.wait(1.2);c:Disconnect()
 table.sort(ft,function(a,b) return a>b end);table.insert(res[mode],{ft[1] or 0,ft[2] or 0})
end
pr:Invoke('close');pr:Invoke('motionPrefs',nil)
local out={}
for mode,list in pairs(res) do
 local w,s,m=0,0,0;for _,p in ipairs(list) do w+=p[1];s+=p[2];m=math.max(m,p[1]) end
 out[mode]=string.format('mean worst %.1f, mean 2nd %.1f, max %.1f',w/#list,s/#list,m);out[mode..'Worst']=w/#list
end
out.delta=math.floor((out.normalWorst-out.reducedWorst)*10+.5)/10
return game:GetService('HttpService'):JSONEncode(out)
