local T=require(script.Parent.Parent.ExpeditionUITheme);local Scene=require(script.Parent.SummitCinematic)
local U={}
function U.mount(deps)
 local self={};local result;local controller;local seen={};local active=false;local savingDismissed=false
 local gui=T.make('ScreenGui',game.Players.LocalPlayer.PlayerGui,{Name='SummitResults',DisplayOrder=85,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Enabled=false})
 local root=T.panel(gui,'WinnerBanner',T.cream);root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5);root.Size=UDim2.new(1,-24,1,-20);T.make('UISizeConstraint',root,{MaxSize=Vector2.new(760,680)})
 local header=T.panel(root,'Victory',T.teal);header.Size=UDim2.new(1,0,0,82)
 local title=T.text(header,'SUMMIT • COMPLETE',30);title.Position=UDim2.fromOffset(18,8);title.Size=UDim2.new(1,-130,1,-16);T.mountain(header).Position=UDim2.new(1,-110,0,4)
 local body=T.make('ScrollingFrame',root,{Position=UDim2.fromOffset(16,94),Size=UDim2.new(1,-32,1,-178),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()});T.make('UIListLayout',body,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
 local notice=T.make('ScreenGui',game.Players.LocalPlayer.PlayerGui,{Name='SummitSaveNotice',DisplayOrder=86,ResetOnSpawn=false,Enabled=false})
 local note=T.text(notice,'SUMMIT • Save pending. Stay on the protected summit deck.',17);note.BackgroundTransparency=0;note.BackgroundColor3=T.cream;note.Position=UDim2.new(.15,0,1,-90);note.Size=UDim2.new(.7,0,0,76)
 local go;go=T.button(root,'BACK TO CAMP • BESIDE THE BANK',function() if result then deps.request('summitReturn',{resultId=result.id});go.Text='RETURNING • SAVING…' else savingDismissed=true;self.close();notice.Enabled=true end end,T.gold);go.Position=UDim2.new(0,16,1,-70);go.Size=UDim2.new(1,-32,0,54)
 local function row(head,detail,color)
  local p=T.panel(body,head,color or T.gold);p.Size=UDim2.new(1,-6,0,104)
  local h=T.text(p,head,21);h.Position=UDim2.fromOffset(12,6);h.Size=UDim2.new(1,-24,0,32)
  local d=T.text(p,detail,17);d.Font=Enum.Font.GothamMedium;d.Position=UDim2.fromOffset(12,40);d.Size=UDim2.new(1,-24,0,58)
  T.fitRow(p,h,d,104)
 end
 function self.show()
  if not result then return end
  for _,v in body:GetChildren() do if v:IsA('GuiObject') then v:Destroy() end end
  gui.Enabled=true;go.Visible=true;go.Text='BACK TO CAMP • BESIDE THE BANK'
  row(result.route..(result.mixedRoute and ' • MIXED ROUTE' or ''),string.format('%dm %02ds • Expedition time',math.floor(result.elapsedSeconds/60),result.elapsedSeconds%60),T.teal)
  row('FINDS & SAFE CARGO',(result.found.creatures or 0)..' creatures found • '..(result.found.heartstones or 0)..' Heartstones found\n'..result.carriedCreatures..' creatures safely carried • '..#result.carried..' total items')
  row('NEW SPECIES',result.newBankedSpecies..' permanently collected during this expedition\n'..result.newUnbankedSpecies..' new carried species • Bank them to collect!',Color3.fromRGB(207,186,242))
  local prizes={};for _,v in result.rewards.cosmetics do table.insert(prizes,v.name) end
  row('CONFIRMED PRIZES','+'..result.rewards.coins..' coins • +'..result.rewards.points..' Summit Points\n'..(#prizes>0 and table.concat(prizes,' • ') or 'Another successful summit saved.'))
  row('NEXT COSMETIC',result.nextMilestone and (result.nextMilestone.name..' • '..result.nextMilestone.remaining..' more summits') or 'You earned the complete summit set.',T.teal)
  row('YOUR CARGO IS STILL WITH YOU','Extraction does not bank finds. Use the bank beside your return point. '..(result.reviewEconomy and 'Local review: prize values are provisional.' or ''),T.cream)
  T.button(body,'Replay your summit moment',function() self.play() end,T.cream)
  game.GuiService.SelectedObject=go
  body.CanvasPosition=Vector2.zero;task.defer(function() if body.Parent then body.CanvasPosition=Vector2.zero end end)
 end
 function self.play()
  if not result then return end;if controller then controller.destroy() end
  gui.Enabled=false;controller=Scene.play(result,deps.settings(),{finished=self.show})
 end
 local function activate() deps.closeOthers();active=true;game.Players.LocalPlayer:SetAttribute('CC_SummitPresentation',true);deps.modal(true) end
 function self.update(st)
  local summit=st.summit or {}
  if summit.status=='saving' then
   if savingDismissed then notice.Enabled=true;return end
   if not active then activate();for _,v in body:GetChildren() do if v:IsA('GuiObject') then v:Destroy() end end;row('WAITING FOR CONFIRMATION','Your completion is being saved. Prizes appear only after confirmation. You can close this notice and move around the protected summit deck while we retry.',T.cream) end
   gui.Enabled=true;go.Visible=true;go.Text='CLOSE NOTICE • SAVE PENDING';title.Text='CONFIRMING SUMMIT…';game.GuiService.SelectedObject=go;return
  end
  notice.Enabled=false;savingDismissed=false
  if summit.result then
   result=summit.result;title.Text='SUMMIT • COMPLETE'
   if not active then activate() end
   if not seen[result.id] then seen[result.id]=true;self.play() end
  elseif active then self.close() end
 end
 function self.close()
  if controller then controller.destroy();controller=nil end;gui.Enabled=false;active=false;result=nil
  game.Players.LocalPlayer:SetAttribute('CC_SummitPresentation',false);deps.modal(false)
 end
 function self.isOpen() return active end
 function self.fx(e) if e.kind=='summitReplay' and result and e.id==result.id then self.play() end end
 function self.destroy() self.close();gui:Destroy();notice:Destroy() end
 return self
end
return U
