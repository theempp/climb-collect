local T=require(script.Parent.Theme)
local W=require(script.Parent.Widgets)
local GuiService=game:GetService('GuiService')
local F={};F.__index=F
function F.new(root)
 local self=setmetatable({root=root,queue={},serial=0,alive=true},F)
 self.host=W.panel(root,'Toast',UDim2.new(.6,0,0,58),UDim2.new(.2,0,0,68));self.host.ZIndex=40;self.host.Visible=false
 local icon=W.icon(self.host,'Profile',UDim2.fromOffset(40,40),UDim2.fromOffset(8,8));icon.ZIndex=41
 self.label=W.text(self.host,'',UDim2.new(1,-68,1,-12),UDim2.fromOffset(56,6),T.bold,14);self.label.ZIndex=41
 self.tooltip=W.panel(root,'Tooltip',UDim2.fromOffset(280,64),UDim2.new(.5,-140,0,124));self.tooltip.ZIndex=80;self.tooltip.Visible=false
 self.tooltipText=W.text(self.tooltip,'',UDim2.new(1,-24,1,-12),UDim2.fromOffset(12,6),nil,14);self.tooltipText.ZIndex=81
 local function attach(o)
  if not o:IsA('GuiButton') then return end
  local function show() local text=o:GetAttribute('Tooltip');if text and self.alive and not self.host.Visible then self.tooltipText.Text=text;self.tooltip.Visible=true;self.tooltipOwner=o end end
  local function hide() if self.tooltipOwner==o then self.tooltip.Visible=false;self.tooltipOwner=nil end end
  o.MouseEnter:Connect(show);o.MouseLeave:Connect(hide);o.SelectionGained:Connect(show);o.SelectionLost:Connect(hide);o.Destroying:Connect(hide)
 end
 self.added=root.DescendantAdded:Connect(attach)
 self.focus=GuiService:GetPropertyChangedSignal('SelectedObject'):Connect(function()
  local selected=GuiService.SelectedObject
  if self.modal and selected and not selected:IsDescendantOf(self.modal) then GuiService.SelectedObject=self.modal.Dialog.Confirm end
 end)
 return self
end
function F:toast(message,priority)
 if not self.alive or type(message)~='string' or message=='' then return end
 self.tooltip.Visible=false;self.tooltipOwner=nil
 if message==self.label.Text and self.host.Visible or table.find(self.queue,message) then return end
 if priority then self.serial+=1;self.host.Visible=false;table.clear(self.queue) end
 if #self.queue>=4 then table.remove(self.queue,1) end
 table.insert(self.queue,message)
 if self.host.Visible then return end
 self.serial+=1;local serial=self.serial
 local function nextToast()
  if not self.alive or serial~=self.serial then return end
  local m=table.remove(self.queue,1)
  if not m then self.host.Visible=false;return end
  self.host.Visible=true;self.label.Text=m
  task.delay(4,nextToast)
 end
 nextToast()
end
function F:confirm(title,description,onConfirm)
 self:close();self.previousFocus=GuiService.SelectedObject
 local shade=W.frame(self.root,'Confirmation',UDim2.fromScale(1,1),nil,T.navy);shade.BackgroundTransparency=.15;shade.ZIndex=70;shade.Active=true;self.modal=shade
 local f=W.panel(shade,'Dialog',UDim2.new(.86,0,0,226),UDim2.fromScale(.5,.5));f.AnchorPoint=Vector2.new(.5,.5);f.ZIndex=71
 W.new('UISizeConstraint',f,{MaxSize=Vector2.new(480,226)})
 W.text(f,title,UDim2.new(1,-32,0,40),UDim2.fromOffset(16,14),T.display,22).ZIndex=72
 local descriptionLabel=W.text(f,description,UDim2.new(1,-32,0,86),UDim2.fromOffset(16,58),nil,15,T.muted);descriptionLabel.Name='Description';descriptionLabel.ZIndex=72
 W.button(f,'Cancel','Cancel',UDim2.new(.5,-24,0,48),UDim2.new(0,16,1,-64),function() self:close() end,'quiet').ZIndex=72
 local confirm=W.button(f,'Confirm','Confirm',UDim2.new(.5,-24,0,48),UDim2.new(.5,8,1,-64),function() self:close();onConfirm() end,'gold');confirm.ZIndex=72
 if game:GetService('UserInputService').GamepadEnabled then GuiService.SelectedObject=confirm end
end
function F:reveal(title,description,species)
 -- Called only by authoritative state transitions or acknowledged outcomes.
 self:confirm(title,description,function() end)
 local f=self.modal and self.modal:FindFirstChild('Dialog')
 if f then
  f.Confirm.Text='Continue';f.Cancel.Visible=false;f.Confirm.Size=UDim2.new(1,-32,0,48);f.Confirm.Position=UDim2.new(0,16,1,-64)
  if species then
   f.Size=UDim2.new(.86,0,0,300);f.UISizeConstraint.MaxSize=Vector2.new(480,300)
   f.Description.Position=UDim2.fromOffset(16,158);f.Description.Size=UDim2.new(1,-32,0,64);f.Description.TextXAlignment=Enum.TextXAlignment.Center
   local portrait=W.portrait(f,species,UDim2.fromOffset(80,80),UDim2.new(.5,-40,0,70));portrait.ZIndex=72
   for _,o in ipairs(portrait:GetDescendants()) do if o:IsA('GuiObject') then o.ZIndex=73 end end
  end
  if not T.prefs.reducedMotion then
   local scale=W.new('UIScale',f,{Scale=.94})
   game:GetService('TweenService'):Create(scale,TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1}):Play()
  end
 end
end
function F:close()
 if not self.modal then return false end
 local modal=self.modal;self.modal=nil;modal:Destroy()
 if self.previousFocus and self.previousFocus.Parent then GuiService.SelectedObject=self.previousFocus else GuiService.SelectedObject=nil end
 self.previousFocus=nil;return true
end
function F:destroy() self.alive=false;self:close();self.added:Disconnect();self.focus:Disconnect();self.host:Destroy();self.tooltip:Destroy() end
return F
