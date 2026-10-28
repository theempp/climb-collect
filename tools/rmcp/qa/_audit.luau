SIZES={{749,330},{844,390},{932,430},{1024,700},{1180,780},{1600,860}}
-- HUD v2 QA only (needs ReplicatedStorage.StudioAids=true for the UIProbe; never save with it on).
-- Every hub/tab at several root sizes: each visible GuiObject must sit inside its parent (parts tagged Overhang must
-- stay inside the grandparent; Decor is exempt), children of a ScrollingFrame must fit its width, text must fit,
-- buttons >= 44 px, and text-bearing siblings must not overlap.
local pg=game.Players.LocalPlayer.PlayerGui
local gui=pg:WaitForChild('MountainHUD')
local root=gui.SafeRoot
local probe=gui:WaitForChild('UIProbe',10)
if not probe then return 'NO PROBE' end
local SIZES=SIZES or {{749,330},{1024,700},{1180,780},{1600,860}}
local errors,screens,objects={},0,0
local function visible(o) local p=o while p and p~=gui do if p:IsA('GuiObject') and not p.Visible then return false end;p=p.Parent end return true end
local function tagged(o,k) local p=o while p and p~=gui do if p:GetAttribute(k) then return true end;p=p.Parent end return false end
local function inside(a,b,tol)
 local a0,a1=a.AbsolutePosition,a.AbsolutePosition+a.AbsoluteSize;local b0,b1=b.AbsolutePosition,b.AbsolutePosition+b.AbsoluteSize
 return a0.X>=b0.X-tol and a0.Y>=b0.Y-tol and a1.X<=b1.X+tol and a1.Y<=b1.Y+tol
end
local function overlap(a,b)
 local a0,a1=a.AbsolutePosition,a.AbsolutePosition+a.AbsoluteSize;local b0,b1=b.AbsolutePosition,b.AbsolutePosition+b.AbsoluteSize
 return a0.X<b1.X-1 and b0.X<a1.X-1 and a0.Y<b1.Y-1 and b0.Y<a1.Y-1
end
local function texty(o) return (o:IsA('TextLabel') and o.Text~='') or o:IsA('TextButton') or o:IsA('TextBox') end
local function add(where,msg) if #errors<200 then table.insert(errors,where..' '..msg) end end
local function check(where)
 local hub=root.HubShade.Hub
 if not inside(hub,root,0) then add(where,'hub outside root') end
 for _,o in ipairs(root.HubShade:GetDescendants()) do
  if o:IsA('GuiObject') and visible(o) and not tagged(o,'Decor') then
   objects+=1
   local p=o.Parent
   if p:IsA('ScrollingFrame') then
    local x0,x1=o.AbsolutePosition.X,o.AbsolutePosition.X+o.AbsoluteSize.X
    if (x0<p.AbsolutePosition.X-1 or x1>p.AbsolutePosition.X+p.AbsoluteSize.X+1) then add(where,'wider than scroll: '..o:GetFullName():match('Hub%.(.*)$')) end
   elseif p:IsA('GuiObject') then
    local ref=if o:GetAttribute('Overhang') then p.Parent else p
    if ref and ref:IsA('GuiObject') and not ref:IsA('ScrollingFrame') and not inside(o,ref,1.5) then add(where,'spills: '..o:GetFullName():match('HubShade%.(.*)$')) end
   end
   if (o:IsA('TextLabel') or o:IsA('TextButton')) and o.Text~='' and not o.TextFits then add(where,'text: '..o:GetFullName():match('HubShade%.(.*)$')) end
   if o:IsA('GuiButton') and (o.AbsoluteSize.Y<44 or o.AbsoluteSize.X<44) then add(where,'touch: '..o.Name) end
  end
 end
 for _,p in ipairs(root.HubShade:GetDescendants()) do
  if p:IsA('GuiObject') and visible(p) then
   local kids={};for _,c in ipairs(p:GetChildren()) do if c:IsA('GuiObject') and visible(c) and texty(c) and not tagged(c,'Decor') then table.insert(kids,c) end end
   for i=1,#kids do for j=i+1,#kids do if overlap(kids[i],kids[j]) then add(where,'overlap: '..kids[i].Name..' / '..kids[j].Name..' in '..p.Name) end end end
  end
 end
end
local HUBS={'Creatures','Discovery','Sanctuary','Mountain','Social','Profile','Shop','Settings'}
for _,size in ipairs(SIZES) do
 root.Size=UDim2.fromOffset(size[1],size[2]);task.wait(.15)
 for _,hub in ipairs(HUBS) do
  probe:Invoke('open',hub);task.wait(.05)
  local tabs={};for _,o in ipairs(root.HubShade.Hub.Tabs:GetChildren()) do if o:IsA('TextButton') and o.Name:sub(1,3)=='Tab' then table.insert(tabs,o.Name:sub(4)) end end
  for _,tab in ipairs(tabs) do
   probe:Invoke('tab',tab);task.wait(.05);screens+=1
   check(size[1]..'x'..size[2]..' '..hub..'/'..tab)
  end
 end
 probe:Invoke('close')
end
root.Size=UDim2.fromScale(1,1);task.wait(.1)
return game:GetService('HttpService'):JSONEncode({sizes=#SIZES,screens=screens,objects=objects,errors=#errors,list=errors})
