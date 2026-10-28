-- P6 QA (StudioAids on, Play, Client): loop budget per HUD state and across a Shop scroll sweep, Shop open frame cost,
-- close cleanup, and the Reduce effects / LOW gates on every state + Shop + reveal (local pref override via UIProbe motionPrefs).
local RS=game:GetService('RunService')
local gui=game.Players.LocalPlayer.PlayerGui:WaitForChild('MountainHUD');local pr=gui:WaitForChild('UIProbe',10);local root=gui.SafeRoot
local out={states={},shop={},reduced={},low={}}
local function st() local s=pr:Invoke('motionStats');return {loops=s.loops,tweens=s.tweens,byCat=s.byCat,oneShots=s.oneShots} end
local function worstFor(sec) local w,over=0,0;local c=RS.Heartbeat:Connect(function(dt) w=math.max(w,dt);if dt>1/30 then over+=1 end end);task.wait(sec);c:Disconnect();return {worst=math.floor(w*1e4)/10,over33=over} end
local STATES={'rest','carry','regrab','chase','sanctuary','battle'}
pr:Invoke('close');pr:Invoke('motionPrefs',nil)
for _,s in ipairs(STATES) do pr:Invoke('hudState',s);task.wait(1.2);out.states[s]=st() end
pr:Invoke('hudState','live');task.wait(.5)
-- Shop: open frame cost (open + .2 s fade), loops at the top, max loops over a full scroll sweep.
local restN=#gui:GetDescendants()
pr:Invoke('open','Shop');out.shop.openFrames=worstFor(.6);task.wait(.6);out.shop.top=st()
local sf=root.HubShade.Hub.Content.Scroll;local maxL,maxAt,maxCat=0,0,nil;local overBudget={}
local y=0;local endY=math.max(0,sf.AbsoluteCanvasSize.Y-sf.AbsoluteWindowSize.Y)
while y<=endY+1 do
 sf.CanvasPosition=Vector2.new(0,y);task.wait(.25);local s=st()
 if s.loops>maxL then maxL,maxAt,maxCat=s.loops,y,s.byCat end
 local c=s.byCat or {};if s.loops>12 or (c.shine or 0)>3 or (c.idle or 0)>6 then table.insert(overBudget,{y=y,s=s}) end
 y+=120;endY=math.max(0,sf.AbsoluteCanvasSize.Y-sf.AbsoluteWindowSize.Y)
end
out.shop.sweep={max=maxL,at=maxAt,byCat=maxCat,end_=endY,overBudget=overBudget}
for _,title in ipairs({'EGGS','BAT SKINS'}) do
 for _,h in ipairs(sf:GetDescendants()) do if h.Name=='SectionHeader' and h:FindFirstChild('Title') and h.Title.Text==title then
  sf.CanvasPosition=Vector2.new(0,math.max(0,h.AbsolutePosition.Y-sf.AbsolutePosition.Y+sf.CanvasPosition.Y-4));task.wait(.5);out.shop[title]=st() end end
end
pr:Invoke('close');task.wait(.3)
out.shop.closed={stats=st(),descendants=#gui:GetDescendants(),restBefore=restN,closing=root:FindFirstChild('HubShadeClosing')~=nil,shade=root:FindFirstChild('HubShade')~=nil}
-- Reveal over the open Shop (cover rule): reveal loops only; Collect not interactable until it shows (5.7 s), then it is.
pr:Invoke('open','Shop');task.wait(1);pr:Invoke('reveal');task.wait(1)
local rv=root:FindFirstChild('HatchReveal');local cta=rv and rv:FindFirstChild('Collect',true)
out.reveal={during=st(),ctaEarly=cta and cta.Interactable,title=rv and rv:FindFirstChild('Title',true) and rv:FindFirstChild('Title',true).Text.Text}
task.wait(5.2);out.reveal.ctaLate=cta and cta.Interactable;out.reveal.titleLanded=rv and rv:FindFirstChild('Title',true).Text.Text;out.reveal.after=st()
pr:Invoke('close');task.wait(.3)
-- Reduce effects (reducedMotion + simplifiedVFX) and LOW (effectsTier 0): loops 0 everywhere; LOW hides rays.
local function gateRun(prefs,key)
 pr:Invoke('motionPrefs',prefs)
 for _,s in ipairs(STATES) do pr:Invoke('hudState',s);task.wait(.4);out[key][s]=st() end
 pr:Invoke('hudState','live');task.wait(.3)
 pr:Invoke('open','Shop');task.wait(.6);local s=st();local rays={}
 for _,o in ipairs(root.HubShade:GetDescendants()) do local m=o:GetAttribute('Motion');if m and string.sub(m,1,5)=='rays.' then table.insert(rays,o.Name..'='..tostring(o.Visible)) end end
 local hub=root.HubShade.Hub;local sc=hub:FindFirstChild('MotionScale')
 out[key].shop={stats=s,rays=rays,hubScale=sc and sc.Scale or 1}
 pr:Invoke('close');task.wait(.05);out[key].closeInstant=root:FindFirstChild('HubShadeClosing')==nil
 pr:Invoke('reveal');task.wait(.15);local rv=root:FindFirstChild('HatchReveal')
 local cta=rv and rv:FindFirstChild('Collect',true);local card=rv and rv:FindFirstChild('Card',true)
 out[key].reveal={stats=st(),ctaVisible=cta and cta.Visible,cardScale=card and card:FindFirstChild('MotionScale') and card.MotionScale.Scale or 1}
 pr:Invoke('close')
end
gateRun({reducedMotion=true,simplifiedVFX=true},'reduced')
gateRun({effectsTier=0},'low')
pr:Invoke('motionPrefs',nil);pr:Invoke('hudState','live');task.wait(.3);out.after=st()
return game:GetService('HttpService'):JSONEncode(out)
