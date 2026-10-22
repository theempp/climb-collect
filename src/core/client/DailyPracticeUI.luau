local T=require(script.Parent.Parent.ExpeditionUITheme)
local U={}
function U.mount(deps)
 local self={};local state={};local root=T.panel(deps.parent,'DailyPractice',T.cream);root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5);root.Size=UDim2.new(1,-30,1,-22);root.Visible=false;root.ZIndex=75
 T.make('UISizeConstraint',root,{MaxSize=Vector2.new(620,500)})
 local header=T.panel(root,'PassportHeader',T.teal);header.Size=UDim2.new(1,0,0,64)
 local title=T.text(header,'DAILY PRACTICE • FREE',24);title.Position=UDim2.fromOffset(16,8);title.Size=UDim2.new(1,-88,0,48)
 local body=T.make('ScrollingFrame',root,{Position=UDim2.fromOffset(14,68),Size=UDim2.new(1,-28,1,-82),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()});T.make('UIListLayout',body,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
 local stampCard=T.panel(body,'PracticePassport',Color3.fromRGB(255,231,167));stampCard.Size=UDim2.new(1,-6,0,120);stampCard.LayoutOrder=0
 local stampTitle=T.text(stampCard,'YOUR PRACTICE PASSPORT',18);stampTitle.Position=UDim2.fromOffset(10,5);stampTitle.Size=UDim2.new(1,-20,0,34)
 local stamps={}
 for i=1,7 do local cell=T.panel(stampCard,'Stamp'..i,T.cream);cell.Position=UDim2.new((i-1)/7,6,0,48);cell.Size=UDim2.new(1/7,-12,0,54);local mark=T.text(cell,tostring(i),20);mark.Size=UDim2.fromScale(1,1);mark.TextXAlignment=Enum.TextXAlignment.Center;stamps[i]={cell=cell,mark=mark} end
 local route=T.text(body,'',21);route.Size=UDim2.new(1,-6,0,78)
 local progress=T.text(body,'',18);progress.Size=UDim2.new(1,-6,0,78)
 route.LayoutOrder=1;progress.LayoutOrder=2;T.fitText(route,78);T.fitText(progress,78)
 function self.close() root.Visible=false;deps.modal(false) end
 local close=T.button(root,'×',self.close);close.Position=UDim2.new(1,-60,0,7);close.Size=UDim2.fromOffset(52,50)
 T.button(body,'Start • take your time',function() deps.request('practiceDailyStart',{timed=false});self.close() end,T.teal)
 T.button(body,'Start • optional timer',function() deps.request('practiceDailyStart',{timed=true});self.close() end,T.gold)
 T.button(body,'Cancel current attempt',function() deps.request('practiceDailyCancel');self.close() end)
 local hud=T.panel(deps.parent,'DailyProgress',T.teal);hud.AnchorPoint=Vector2.new(.5,0);hud.Position=UDim2.new(.5,0,0,8);hud.Size=UDim2.fromOffset(270,52);hud.Visible=false
 local text=T.text(hud,'',16);text.Size=UDim2.new(1,-12,1,-4);text.Position=UDim2.fromOffset(6,2)
 function self.open() deps.closeOthers();root.Visible=true;deps.modal(true);game.GuiService.SelectedObject=close end
 function self.isOpen() return root.Visible end
 function self.update(st)
  state=st.dailyPractice or {};for i,stamp in stamps do local earned=i<=(state.stamps or 0);stamp.cell.BackgroundColor3=earned and T.teal or T.cream;stamp.mark.Text=earned and '✓' or tostring(i) end;local parts={};for _,s in state.sections or {} do table.insert(parts,(s:gsub('Practice:',''))) end
  local left=math.max(0,(state.resetAt or 0)-(st.serverNow or os.time()))
  route.Text='TODAY: '..table.concat(parts,' → ')..string.format('\nNext circuit in %dh %dm • 00:00 UTC',math.floor(left/3600),math.floor(left%3600/60))
  progress.Text=(state.stamps or 0)..' / 7 stamps • Earn the Practice Pennant\n'..(state.status=='replay' and 'Today’s stamp is saved. Replay freely.' or 'No streak needed. One saved stamp each day.')
  hud.Visible=state.active==true and not root.Visible
  text.Text=state.status=='saving' and 'Practice complete • confirming save…' or ('DAILY '..math.min(state.next or 1,#parts)..' / '..#parts..(state.timed and (' • '..(state.elapsed or 0)..'s') or ' • TAKE YOUR TIME'))
 end
 game.ContextActionService:BindActionAtPriority('CC_DailyClose',function(_,s) if not root.Visible then return Enum.ContextActionResult.Pass end;if s==Enum.UserInputState.Begin then self.close() end;return Enum.ContextActionResult.Sink end,false,3450,Enum.KeyCode.ButtonB,Enum.KeyCode.Escape)
 function self.destroy() self.close();root:Destroy();hud:Destroy();game.ContextActionService:UnbindAction('CC_DailyClose') end
 return self
end
return U
