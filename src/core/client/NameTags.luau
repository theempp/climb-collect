local Players,Run,CAS=game:GetService('Players'),game:GetService('RunService'),game:GetService('ContextActionService')
local T=require(script.Parent.Parent.ExpeditionUITheme)
local N={}
function N.mount(deps)
 local self={rows={},tags={},requestId=0,pending=nil};local localPlayer=Players.LocalPlayer;local nearest
 local function inspect(id)
  self.requestId+=1;self.pending=tostring(self.requestId)..':'..id
  deps.profile.open(nil);self.generation=deps.profile.generation;deps.request('profileInspect',{subjectUserId=id,requestId=self.pending})
 end
 function self.fx(p)
  if p.kind=='profileInspect' and p.requestId==self.pending then self.pending=nil;if self.generation~=deps.profile.generation or not deps.profile.isOpen() then return end;if p.status=='ok' then deps.profile.open(p.card) else deps.profile.unavailable('This explorer is '..p.status..'. Move nearby on safe ground and try again.') end end
 end
 function self.update(st) self.rows=st.playerTags or {} end
 local elapsed=0
 local conn=Run.RenderStepped:Connect(function(dt)
  elapsed+=dt;if elapsed<.1 then return end;elapsed=0;nearest=nil;local nearestD=math.huge;local keep={}
  local root=localPlayer.Character and localPlayer.Character:FindFirstChild('HumanoidRootPart');local camera=workspace.CurrentCamera
  for _,row in self.rows do
   local p=Players:GetPlayerByUserId(row.userId);local ch=p and p.Character;local head=ch and ch:FindFirstChild('Head');local hr=ch and ch:FindFirstChild('HumanoidRootPart')
   if head and hr and root then
    local d=(hr.Position-root.Position).Magnitude;local _,onScreen=camera:WorldToViewportPoint(head.Position)
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
    local ignored={localPlayer.Character,ch};local hit
    -- Ignore invisible gameplay volumes, but opaque non-colliding signs still occlude.
    for _=1,8 do
     params.FilterDescendantsInstances=ignored
     hit=workspace:Raycast(camera.CFrame.Position,head.Position-camera.CFrame.Position,params)
     if not hit or not hit.Instance:IsA('BasePart') or hit.Instance.Transparency<.95 then break end
     table.insert(ignored,hit.Instance)
    end
    if d<=60 and onScreen and not hit then
     keep[row.userId]=true;local tag=self.tags[row.userId]
     if not tag then
      local gui=T.make('BillboardGui',deps.parent,{Name='ExplorerTag',Adornee=head,Size=UDim2.fromOffset(220,68),StudsOffsetWorldSpace=Vector3.new(0,3,0),AlwaysOnTop=false,MaxDistance=60,Active=true})
      local b=T.button(gui,'',function() inspect(row.userId) end,T.gold);b.Size=UDim2.fromScale(1,1);tag={gui=gui,button=b};self.tags[row.userId]=tag
     end
     tag.gui.Adornee=head;tag.gui.Enabled=not localPlayer:GetAttribute('CC_MenuOpen');tag.button.Active=d<=25;tag.button.Selectable=d<=25
     tag.button.Text=d<=25 and (row.displayName..' • Lv '..row.level..'\n'..row.title) or row.displayName
     local width=d<=25 and 260 or 180
     local height=game.TextService:GetTextSize(tag.button.Text,tag.button.TextSize,tag.button.Font,Vector2.new(width-16,1000)).Y+16
     tag.gui.Size=UDim2.fromOffset(width,math.max(d<=25 and 68 or 36,height))
     local earned=require(script.Parent.Parent.EarnedCosmetics)[row.frameId];tag.button.BackgroundColor3=earned and earned.color or T.gold
     if d<=25 and d<nearestD then nearest=row.userId;nearestD=d end
    end
   end
  end
  for id,tag in self.tags do if not keep[id] then tag.gui:Destroy();self.tags[id]=nil end end
 end)
 CAS:BindActionAtPriority('CC_InspectExplorer',function(_,s) if nearest and not localPlayer:GetAttribute('CC_MenuOpen') then if s==Enum.UserInputState.Begin then inspect(nearest) end return Enum.ContextActionResult.Sink end return Enum.ContextActionResult.Pass end,false,3200,Enum.KeyCode.ButtonR3)
 function self.destroy() conn:Disconnect();CAS:UnbindAction('CC_InspectExplorer');for _,tag in self.tags do tag.gui:Destroy() end;self.tags={} end
 return self
end
return N
