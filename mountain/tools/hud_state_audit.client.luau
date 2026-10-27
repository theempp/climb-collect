-- Read-only: run after real navigation input or a clearly labeled combat fixture.
local pg=game.Players.LocalPlayer.PlayerGui
local hud=pg:WaitForChild('MountainHUD');local root=hud.SafeRoot
local function visible(o)
 while o and o~=pg do if o:IsA('GuiObject') and not o.Visible then return false end;o=o.Parent end
 return true
end
local function intersects(a,b)
 local p,q=a.AbsolutePosition,b.AbsolutePosition;local s,t=a.AbsoluteSize,b.AbsoluteSize
 return p.X<q.X+t.X and q.X<p.X+s.X and p.Y<q.Y+t.Y and q.Y<p.Y+s.Y
end
local errors={};local controls={};local native={}
local touch=pg:FindFirstChild('TouchGui')
for _,n in ipairs({'DynamicThumbstickFrame','ThumbstickFrame','JumpButton'}) do
 local o=touch and touch:FindFirstChild(n,true);if o and visible(o) then table.insert(native,o) end
end
for _,gui in ipairs({hud,pg:FindFirstChild('MountainSprint')}) do
 if gui then for _,o in ipairs(gui:GetDescendants()) do
  if o:IsA('GuiButton') and visible(o) and not o:FindFirstAncestorWhichIsA('ScrollingFrame') then
   table.insert(controls,o.Name)
   if o.AbsoluteSize.X<44 or o.AbsoluteSize.Y<44 then table.insert(errors,'Small target '..o.Name) end
   for _,n in ipairs(native) do if intersects(o,n) then table.insert(errors,o.Name..' overlaps '..n.Name) end end
  end
 end end
end
local slots=0;for _,o in ipairs(root.Team:GetChildren()) do if o:IsA('GuiButton') then slots+=1 end end
assert(slots==3,'Exactly three active slots')
for _,o in ipairs(root.Team:GetChildren()) do if o:IsA('GuiButton') then
 local portrait=o:FindFirstChild('Portrait')
 if portrait then
  for _,label in ipairs(o:GetChildren()) do if label:IsA('TextLabel') and label.Position.Y.Offset==-41 then
   assert(label.ZIndex>portrait.ZIndex,'Cooldown and level label must render above portrait')
  end end
 end
end end
if root.Navigation.Visible and root.AbsoluteSize.Y<550 then assert(not root.Journey.Visible,'Horizontal navigation must not overlap journey') end
if root.Navigation.Visible then assert(not root.Hint.Visible,'Initial hint must not obscure expanded navigation') end
return game.HttpService:JSONEncode({view=tostring(root.AbsoluteSize),slots=slots,controls=controls,errors=errors,combat=root.Battle.Visible,navigation=root.Navigation.Visible})
