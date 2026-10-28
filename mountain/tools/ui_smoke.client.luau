-- Read-only Studio QA; run against the separate HUD review in Play.
local pg=game.Players.LocalPlayer:WaitForChild('PlayerGui')
local gui=pg:FindFirstChild('MountainHUD')
assert(gui and gui:GetAttribute('BlueprintVersion')==2,'Approved HUD root absent')
local count=0
for _,g in ipairs(pg:GetChildren()) do if g.Name=='MountainHUD' then count+=1 end end
assert(count==1,'Duplicate HUD root')
assert(gui.ScreenInsets==Enum.ScreenInsets.CoreUISafeInsets,'CoreGui safe inset required')
local root=gui:FindFirstChild('SafeRoot');assert(root,'Missing safe root')
local slots=root:FindFirstChild('Team',true);assert(slots,'Missing team') -- Glassbloom: SafeRoot.Hud.Team (battle specials)
local n=0;for _,b in ipairs(slots:GetChildren()) do if b:IsA('TextButton') and b.Name:match('Slot') then n+=1 end end
assert(n==3,'Exactly three creature slots required')
local errors={}
local function inside(o)
 local a,b=o.AbsolutePosition,root.AbsolutePosition;local s,t=o.AbsoluteSize,root.AbsoluteSize
 return a.X>=b.X-1 and a.Y>=b.Y-1 and a.X+s.X<=b.X+t.X+1 and a.Y+s.Y<=b.Y+t.Y+1
end
for _,o in ipairs(root:GetDescendants()) do
 if o:IsA('GuiButton') and o.Visible and o:GetAttribute('QAControl') then
  local visible=true;local p=o.Parent
  while p and p~=root do if p:IsA('GuiObject') and not p.Visible then visible=false end;p=p.Parent end
  if visible and not o:FindFirstAncestorWhichIsA('ScrollingFrame') and not inside(o) then table.insert(errors,o:GetFullName()..' outside safe root') end
 end
end
assert(#errors==0,table.concat(errors,'\n'))
return {root=gui.Name,viewport={root.AbsoluteSize.X,root.AbsoluteSize.Y},slots=n,descendants=#gui:GetDescendants(),boundsErrors=errors}
