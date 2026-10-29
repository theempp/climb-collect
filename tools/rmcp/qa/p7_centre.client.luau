-- P7 §22 live check (StudioAids, real emulator root, no resizing): play each message demo and sample every rendered frame for
-- drawn transient pixels inside the keep-clear centre M (x .28-.72W, y .24-.70H of the full screen). Reports the deepest intrusion
-- (px, the smaller penetration axis) per demo and the piece that caused it. Tolerance .75 px (intel §3).
local pg=game.Players.LocalPlayer.PlayerGui;local gui=pg.MountainHUD;local pr=gui.UIProbe
local origin=pg.MountainHUDScreenProbe.Origin;local probe=pg.MountainHUDScreenProbe
local RS=game:GetService('RunService')
local function drawn(o)
 if o:IsA('TextLabel') or o:IsA('TextButton') then if o.Text~='' and o.TextTransparency<.98 then return true end end
 if (o:IsA('ImageLabel') or o:IsA('ImageButton')) and o.Image~='' and o.ImageTransparency<.98 then return true end
 return o.BackgroundTransparency<.98
end
local function shown(o) local c=o;while c and c~=gui do if c:IsA('GuiObject') and not c.Visible then return false end;if c:IsA('CanvasGroup') and c.GroupTransparency>.98 then return false end;c=c.Parent end;return true end
local function transient(o) local c=o;while c and c~=gui do if c:GetAttribute('HudClass')=='transient' then return c:GetAttribute('HudPiece') or c.Name end;c=c.Parent end end
local out={}
local o0=origin.AbsolutePosition-Vector2.new(1,1);local S=probe.AbsoluteSize
local M={x=.28*S.X,y=.24*S.Y,w=.44*S.X,h=.46*S.Y}
out.screen={S.X,S.Y};out.M={math.floor(M.x),math.floor(M.y),math.floor(M.w),math.floor(M.h)}
for _,demo in ipairs({'run','banner','moment','carry'}) do
 pr:Invoke('close');pr:Invoke('hudState','live');task.wait(.3)
 pr:Invoke('motionDemo',demo)
 local worst,who,frames,t0=0,nil,0,os.clock()
 while os.clock()-t0<3.2 do
  RS.RenderStepped:Wait();frames+=1
  for _,o in ipairs(gui:GetDescendants()) do
   if o:IsA('GuiObject') then
    local piece=transient(o)
    if piece and piece~='reveal' and piece~='card' and drawn(o) and shown(o) then
     local p=o.AbsolutePosition-o0;local s=o.AbsoluteSize
     local dx=math.min(p.X+s.X,M.x+M.w)-math.max(p.X,M.x);local dy=math.min(p.Y+s.Y,M.y+M.h)-math.max(p.Y,M.y)
     if dx>0 and dy>0 then local d=math.min(dx,dy);if d>worst then worst=d;who=piece..'/'..o.Name..string.format('@%.2fs',os.clock()-t0) end end
    end
   end
  end
 end
 out[demo]={intrusion=math.floor(worst*10+.5)/10,by=who,frames=frames,pass=worst<=.75}
end
pr:Invoke('close');pr:Invoke('hudState','live')
local ok=true;for _,d in ipairs({'run','banner','moment','carry'}) do ok=ok and out[d].pass end;out.pass=ok
return game:GetService('HttpService'):JSONEncode(out)
