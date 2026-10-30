-- Glassbloom HUD state audit (P4). QA only: needs ReplicatedStorage.StudioAids=true for the UIProbe; never save with it on.
-- 5 states (rest, carry, chase, sanctuary, battle) x 3 phone sizes via UIProbe hudState fixtures. SafeRoot (and the sprint
-- gui's root) is resized to each size; the Controller then treats the root as the whole screen (no topbar row). Rules are
-- intel §3 / plan §5 with the .75 px tolerance:
--  permanent (HudClass) inside S, clear of C (116x56), T, M, each other and the native jump/thumbstick; GuiButtons off the
--  dynamic-thumbstick region except the centred row (owner 2026-10-27); transients inside S, clear of C, no input on the
--  mountain (the sanctuary Collect is the one exception); owner 2026-10-28 (P7 E): transients may cross T but never M (the
--  player card launcher and the full-screen hatch reveal excepted), measured at their settled box (no Motion scale live);
--  hit areas >= 44; text fits; coverage at 844x390 (rest, chase) =
--  2 px grid union of permanent boxes + the native jump. Returns JSON {errors, list, coverage, ...}.
local pg=game.Players.LocalPlayer.PlayerGui
local gui=pg:WaitForChild('MountainHUD');local root=gui.SafeRoot
local probe=gui:WaitForChild('UIProbe',10)
if not probe then return 'NO PROBE' end
local sprintGui=pg:FindFirstChild('MountainSprint');local sprintRoot=sprintGui and sprintGui:FindFirstChild('SafeRoot')
local SIZES=SIZES or {{749,330},{844,390},{932,430}}
local STATES=STATES or {'rest','carry','chase','sanctuary','sanctuaryOpen','battle'} -- sanctuaryOpen = the sanctuary, card expanded
local TOL=.75
local CENTRED={dock=true,team=true,ability=true,card=true}
local errors,coverage,instances,checked,cardBottoms={},{},{},0,{}
local function add(where,msg) if #errors<300 then table.insert(errors,where..' '..msg) end end
local function visible(o,top) local p=o while p and p~=top do if p:IsA('GuiObject') and not p.Visible then return false end;if p:IsA('LayerCollector') and not p.Enabled then return false end;p=p.Parent end return true end
local function tagged(o,k,top) local p=o while p and p~=top do if p:GetAttribute(k) then return true end;p=p.Parent end return false end
local function box(o,origin) local a=o.AbsolutePosition-origin;return {x=a.X,y=a.Y,w=o.AbsoluteSize.X,h=o.AbsoluteSize.Y} end
local function overlap(a,b) return a.x<b.x+b.w-TOL and b.x<a.x+a.w-TOL and a.y<b.y+b.h-TOL and b.y<a.y+a.h-TOL end
local function inside(a,b) return a.x>=b.x-TOL and a.y>=b.y-TOL and a.x+a.w<=b.x+b.w+TOL and a.y+a.h<=b.y+b.h+TOL end
local function cover(boxes,w,h)
 local cells,count={},0
 for _,b in ipairs(boxes) do
  for gx=math.floor(math.max(0,b.x)/2),math.ceil(math.min(w,b.x+b.w)/2)-1 do for gy=math.floor(math.max(0,b.y)/2),math.ceil(math.min(h,b.y+b.h)/2)-1 do
   local k=gx*100000+gy;if not cells[k] then cells[k]=true;count+=1 end
  end end
 end
 return math.floor(1000*count*4/(w*h)+.5)/10
end
local function check(where,w,h,state)
 local origin=root.AbsolutePosition
 local S={x=0,y=0,w=w,h=h};local Cz={x=0,y=0,w=116,h=56}
 local Tz={x=0,y=.52*h,w=.30*w,h=.48*h};local M={x=.28*w,y=.24*h,w=.44*w,h=.46*h}
 local native,dynamic={},nil;local touch=pg:FindFirstChild('TouchGui')
 for _,n in ipairs({'JumpButton','ThumbstickFrame','DynamicThumbstickFrame'}) do
  local o=touch and touch:FindFirstChild(n,true)
  if o and visible(o,pg) then
   -- Native controls stay at their screen corner when the root is resized (same rule as P.nativeRect in the HUD).
   local a,s=o.AbsolutePosition,o.AbsoluteSize;local g,gs=gui.AbsolutePosition,gui.AbsoluteSize;local dy=(g.Y+gs.Y)-(a.Y+s.Y)
   local b={x=if n=='JumpButton' then w-((g.X+gs.X)-(a.X+s.X))-s.X else a.X-g.X,y=h-dy-s.Y,w=s.X,h=s.Y}
   if n=='DynamicThumbstickFrame' then dynamic=b else table.insert(native,{name=n,box=b}) end
  end
 end
 local perm,trans={}, {}
 for _,g in ipairs({gui,sprintGui}) do if g then for _,o in ipairs(g:GetDescendants()) do
  if o:IsA('GuiObject') and visible(o,g) then
   local class=o:GetAttribute('HudClass')
   if class=='permanent' then table.insert(perm,{o=o,piece=o:GetAttribute('HudPiece'),box=box(o,origin)})
   elseif class=='transient' then table.insert(trans,{o=o,piece=o:GetAttribute('HudPiece'),box=box(o,origin)}) end
   if (o:IsA('TextLabel') or o:IsA('TextButton')) and o.Text~='' and o.TextTransparency<1 and not tagged(o,'Decor',g) and not o.TextFits then add(where,'text: '..o:GetFullName():match('[^%.]+%.[^%.]+$')) end
   -- Touch targets: a control's Hit child (W.hit) is its target; controls without one are measured themselves.
   if o:IsA('GuiButton') and not o:FindFirstAncestor('HubShade') and not (o.Name~='Hit' and o:FindFirstChild('Hit')) then
    local b=box(o,origin);local name=if o.Name=='Hit' then o.Parent.Name else o.Name
    if b.w<44-TOL or b.h<44-TOL then add(where,'touch: '..name..' '..math.floor(b.w)..'x'..math.floor(b.h)) end
   end
  end
 end end end
 for i,a in ipairs(perm) do
  checked+=1
  if not inside(a.box,S) then add(where,a.piece..' outside S') end
  for name,z in pairs({C=Cz,T=Tz,M=M}) do if overlap(a.box,z) then add(where,a.piece..' overlaps '..name) end end
  for j=i+1,#perm do local b=perm[j];if not a.o:IsDescendantOf(b.o) and not b.o:IsDescendantOf(a.o) and overlap(a.box,b.box) then add(where,a.piece..' overlaps '..b.piece) end end
  for _,n in ipairs(native) do if overlap(a.box,n.box) then add(where,a.piece..' overlaps '..n.name) end end
 end
 if dynamic then
  for _,a in ipairs(perm) do
   if not CENTRED[a.piece] then
    for _,o in ipairs(a.o:GetDescendants()) do if o:IsA('GuiButton') and visible(o,gui) and overlap(box(o,origin),dynamic) then add(where,a.piece..' button over DynamicThumbstickFrame') end end
    if a.o:IsA('GuiButton') and overlap(a.box,dynamic) then add(where,a.piece..' over DynamicThumbstickFrame') end
   end
  end
 end
 for _,a in ipairs(trans) do
  checked+=1
  if not inside(a.box,S) then add(where,a.piece..' outside S') end
  if overlap(a.box,Cz) then add(where,a.piece..' touches C') end
  if a.piece~='card' and a.piece~='reveal' and overlap(a.box,M) then add(where,a.piece..' enters M') end
  if state~='sanctuary' and state~='sanctuaryOpen' and a.piece~='card' then
   for _,o in ipairs(a.o:GetDescendants()) do if o:IsA('GuiObject') and o.Active and visible(o,gui) then add(where,a.piece..' takes input on the mountain ('..o.Name..')') end end
  end
 end
 -- hud-polish E: sanctuary = compact card shown, launcher hidden; sanctuaryOpen = expanded (launcher shown). Both on the dock axis,
 -- the same bottom per size, ending >= 10 (x HUD scale) above the dock top.
 if state=='sanctuary' or state=='sanctuaryOpen' then
  local layer=root:FindFirstChild('Hud');local card=layer and layer:FindFirstChild('PlayerCard');local dock=layer and layer:FindFirstChild('Dock',true)
  local open=state=='sanctuaryOpen';local us=layer and layer:FindFirstChildOfClass('UIScale');local s=if us then us.Scale else 1
  if not (card and card.Visible) then add(where,'player card hidden')
  elseif card.Launcher.Visible~=open then add(where,'launcher '..(if open then 'hidden when expanded' else 'shown when compact'))
  else
   local cb=box(card,origin);local bottom=cb.y+cb.h;local key=w..'x'..h;cardBottoms[key]=cardBottoms[key] or bottom
   if math.abs(bottom-cardBottoms[key])>1 then add(where,'card bottom moved between compact and expanded') end
   if dock then local db=box(dock,origin)
    if math.abs(cb.x+cb.w/2-(db.x+db.w/2))>1 then add(where,'card off the dock axis') end
    if bottom>db.y-10*s+TOL then add(where,'card within 10 of the dock') end
   end
  end
 end
 instances[where]=#gui:GetDescendants()
 if w==844 and (state=='rest' or state=='chase') then
  local boxes={};for _,a in ipairs(perm) do table.insert(boxes,a.box) end
  for _,n in ipairs(native) do if n.name=='JumpButton' then table.insert(boxes,n.box) end end
  coverage[state]=cover(boxes,w,h)
 end
end
for _,size in ipairs(SIZES) do
 root.Size=UDim2.fromOffset(size[1],size[2]);if sprintRoot then sprintRoot.Size=root.Size end;task.wait(.2)
 for _,state in ipairs(STATES) do
  probe:Invoke('hudState',state);task.wait(1) -- P6: held messages finish their in part (RUN! settles at .95 s)
  -- P7 E: measure the static box: wait (<= 2 s more) until no Motion scale is live under the HUD (in parts done).
  local t0=os.clock();while os.clock()-t0<2 and gui:FindFirstChild('MotionScale',true) do task.wait(.1) end
  check(size[1]..'x'..size[2]..' '..state,size[1],size[2],state)
 end
end
probe:Invoke('hudState','live')
root.Size=UDim2.fromScale(1,1);if sprintRoot then sprintRoot.Size=root.Size end;task.wait(.1)
return game:GetService('HttpService'):JSONEncode({sizes=#SIZES,states=#STATES,checked=checked,errors=#errors,list=errors,coverage=coverage,instances=instances,gates={rest=11.6,chase=12}})
