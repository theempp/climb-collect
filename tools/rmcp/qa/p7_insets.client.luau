-- P7 R1 QA (StudioAids on, real root: never resizes SafeRoot). A hub and the hatch reveal on the live CoreUISafeInsets root:
-- panel top in screen px (66 ± 1 while the height isn't capped; else 66 + the centring gap), panel horizontally inside the root
-- (device safe area) with the 24 side inset while the width isn't capped (else centred in the root), HubShade rect == screen
-- rect, HatchReveal rect == screen rect, reveal Strip inside the root horizontally (centred in it) and centred on the screen
-- vertically, HUD TopRight (coin pill + gear) hidden during the reveal and back after Collect/close. ±1 px throughout.
local pg=game.Players.LocalPlayer.PlayerGui
local gui=pg:WaitForChild('MountainHUD');local probe=gui:WaitForChild('UIProbe',10);local root=gui.SafeRoot
local sp=pg:WaitForChild('MountainHUDScreenProbe');local origin=sp.Origin
local function bx(o) return {x=o.AbsolutePosition.X,y=o.AbsolutePosition.Y,w=o.AbsoluteSize.X,h=o.AbsoluteSize.Y} end
local function screen() return {x=origin.AbsolutePosition.X,y=origin.AbsolutePosition.Y,w=sp.AbsoluteSize.X,h=sp.AbsoluteSize.Y} end
local function same(a,b) return math.abs(a.x-b.x)<=1 and math.abs(a.y-b.y)<=1 and math.abs(a.w-b.w)<=1 and math.abs(a.h-b.h)<=1 end
local out={root=bx(root),screen=screen(),simulated=root.Size~=UDim2.fromScale(1,1)}
probe:Invoke('close');task.wait(.4)
local tr=root.Hud.TopRight;out.trRest=tr.Visible
probe:Invoke('open','Creatures');task.wait(.6) -- past the deferred open + panel.scale (.2 s)
local shade=root:FindFirstChild('HubShade');local hub=shade and shade:FindFirstChild('Hub')
if hub then
 local s=screen();local p=bx(hub);local h=math.min(660,s.h-76)
 out.panel=p;out.panelTop=p.y-s.y;out.panelTopExpect=66+math.floor((s.h-76-h)/2);out.panelCapped=h==660
 out.panelTopOk=math.abs(out.panelTop-out.panelTopExpect)<=1
 local r=bx(root);local w=math.min(850,r.w-48);out.panelWidthCapped=w==850
 out.panelLeft=p.x-r.x;out.panelRight=r.x+r.w-(p.x+p.w)
 out.panelSidesOk=math.abs(p.w-w)<=1 and math.abs(out.panelLeft-math.floor((r.w-w)/2))<=1 and out.panelLeft>=24-1 and out.panelRight>=24-1
 out.panelBottomOk=s.y+s.h-(p.y+p.h)>=10-1
 out.shade=bx(shade);out.shadeOk=same(out.shade,s)
end
probe:Invoke('close');task.wait(.4)
probe:Invoke('reveal');task.wait(.3)
local rv=root:FindFirstChild('HatchReveal')
if rv then
 out.reveal=bx(rv);out.revealOk=same(out.reveal,screen())
 local strip=rv:FindFirstChild('Strip')
 if strip then
  local b=bx(strip);local s=screen();local r=bx(root);out.strip=b
  out.stripInRootOk=b.x>=r.x-1 and b.x+b.w<=r.x+r.w+1
  out.stripCentreOk=math.abs(b.x+b.w/2-(r.x+r.w/2))<=1 and math.abs(b.y+b.h/2-(s.y+s.h/2))<=1
 end
 local cta=strip and strip:FindFirstChild('Collect');local hit=cta and cta:FindFirstChild('Hit',true)
 if hit and hit:IsA('GuiObject') then out.collectHit={hit.AbsoluteSize.X,hit.AbsoluteSize.Y} end
end
out.trDuringReveal=tr.Visible
probe:Invoke('close');task.wait(.4) -- clears the reveal (as Collect does): the HUD returns
out.trAfter=tr.Visible
out.clipToSafeArea=gui.ClipToDeviceSafeArea
out.pass=out.panelTopOk==true and out.panelSidesOk==true and out.panelBottomOk==true and out.shadeOk==true and out.revealOk==true
 and out.stripInRootOk==true and out.stripCentreOk==true and out.trDuringReveal==false and out.trAfter==out.trRest and out.clipToSafeArea==false
return game:GetService('HttpService'):JSONEncode(out)
