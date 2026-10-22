local T=require(script.Parent.Parent.ExpeditionUITheme)
local A=require(script.Parent.Parent.AchievementRules)
local GS=game:GetService('GuiService')
local CAS=game:GetService('ContextActionService')
local U={}
function U.mount(deps)
 local self={owner=nil,details=nil,card=nil,selected={},connections={}}
 local root=T.panel(deps.parent,'Portfolio',T.cream);root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5);root.Size=UDim2.new(1,-24,1,-16);root.ZIndex=70;root.Visible=false
 T.make('UISizeConstraint',root,{MaxSize=Vector2.new(900,680)})
 local header=T.panel(root,'Header',T.teal);header.Size=UDim2.new(1,0,0,64)
 local title=T.text(header,'FIELD PORTFOLIO',24);title.Position=UDim2.fromOffset(18,8);title.Size=UDim2.new(1,-84,0,48)
 local body=T.make('ScrollingFrame',root,{Name='Content',Position=UDim2.fromOffset(14,76),Size=UDim2.new(1,-28,1,-90),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
 T.make('UIListLayout',body,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
 local previous
 function self.close()
  self.generation=(self.generation or 0)+1;if not root.Visible then return end;root.Visible=false;deps.modal(false);GS.SelectedObject=previous and previous.Parent and previous or nil
 end
 local close=T.button(header,'×',self.close,T.gold);close.Size=UDim2.fromOffset(52,50);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-7,0,7)
 local function row(heading,detail,color)
  local f=T.panel(body,heading,color or Color3.fromRGB(255,231,167));f.Size=UDim2.new(1,-8,0,100)
  local a=T.text(f,heading,21);a.Position=UDim2.fromOffset(12,5);a.Size=UDim2.new(1,-24,0,34)
  local b=T.text(f,detail,17);b.Font=Enum.Font.GothamMedium;b.Position=UDim2.fromOffset(12,40);b.Size=UDim2.new(1,-24,0,54)
  T.fitRow(f,a,b,100)
  return f
 end
 function self.draw()
  for _,c in body:GetChildren() do if c:IsA('GuiObject') then c:Destroy() end end
  local card=self.card;if not card then row('PLAYER UNAVAILABLE',self.message or 'Waiting for a nearby explorer…');return end
  title.Text=card.displayName..' • LEVEL '..card.level
  local hero=row(card.title or 'Explorer','@'..card.username..'  •  '..card.xp..' exploration XP',T.gold)
  for _,v in hero:GetChildren() do if v:IsA('TextLabel') then v.Position+=UDim2.fromOffset(84,0);v.Size-=UDim2.fromOffset(84,0) end end
  T.make('ImageLabel',hero,{BackgroundTransparency=1,Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(80,80),Image='rbxthumb://type=AvatarHeadShot&id='..card.userId..'&w=150&h=150'})
  for _,v in hero:GetChildren() do if v:IsA('TextLabel') then v.Size-=UDim2.fromOffset(110,0) end end
  T.mountain(hero).Position=UDim2.new(1,-108,0,14)
  local identity=T.make('Frame',body,{BackgroundTransparency=1,Size=UDim2.new(1,-8,0,144),LayoutOrder=3})
  for i,v in {{tostring(card.summits),'SUMMITS',T.gold},{tostring(card.collection.collected),'UNIQUE SPECIES',T.teal},{card.collection.percent..'%','COLLECTION',Color3.fromRGB(205,184,245)}} do
   local cardFrame=T.panel(identity,v[2],v[3]);cardFrame.Position=UDim2.new((i-1)/3,4,0,0);cardFrame.Size=UDim2.new(1/3,-8,1,0)
   local value=T.text(cardFrame,v[1],32);value.TextXAlignment=Enum.TextXAlignment.Center;value.Size=UDim2.new(1,-8,0,48);value.Position=UDim2.fromOffset(4,8)
   local caption=T.text(cardFrame,v[2],17);caption.TextXAlignment=Enum.TextXAlignment.Center;caption.Size=UDim2.new(1,-8,0,76);caption.Position=UDim2.fromOffset(4,60)
  end
  local lines={};for _,r in {'Common','Uncommon','Rare','Epic','Legendary'} do local v=card.collection.byRarity[r];table.insert(lines,r..' '..v.collected..'/'..v.obtainable) end
  row('CURRENT OBTAINABLE ROSTER',table.concat(lines,'   •   '))
  local function specimen(heading,b,empty)
   local f=row(heading,b and (b.name..' • '..b.rarity..(b.mutation and b.mutation~='' and (' • '..b.mutation) or '')) or empty)
   if b then local portrait=T.creature(f,b.species);if portrait then portrait.Position=UDim2.fromOffset(6,6);for _,label in f:GetChildren() do if label:IsA('TextLabel') then label.Position+=UDim2.fromOffset(90,0);label.Size-=UDim2.fromOffset(90,0) end end end end
  end
  specimen('YOUR ADVENTURE COMPANION',card.companion,'Choose a companion at your home.')
  for i=1,3 do specimen('SHOWCASE '..i,card.showcase[i],'An open place for your next favourite.') end
  local cosmetics={} for id,yes in card.cosmetics or {} do if yes then table.insert(cosmetics,id) end end
  if card.earnedCosmetic then table.insert(cosmetics,card.earnedCosmetic) end
  for _,id in card.gear or {} do if id~='' then table.insert(cosmetics,id) end end
  row('EXPEDITION STYLE',#cosmetics>0 and table.concat(cosmetics,' • ') or 'Classic expedition kit')
  for route,n in card.summitsByRoute do row(route,n..' successful summits') end
  row('EARNED MILESTONES',#(card.milestones or {})>0 and table.concat(card.milestones,' • ') or 'Your next expedition can start a new chapter.')
  if self.showDetails and self.details then
   local d=self.details
   row('YOUR PRIVATE FIELD NOTES',d.banked..' total banked • '..d.mutationCount..' species / mutation combinations. Only permanent finds count. New obtainable species can lower completion.')
   row('DAILY FIELD PRACTICE',(d.dailyPractice.stamps or 0)..' / 7 saved stamps • No streak required')
   for id,cosmetic in require(script.Parent.Parent.EarnedCosmetics) do
    if d.earnedCosmetics[id] then
     T.button(body,'Wear '..cosmetic.name,function() deps.request('profileEquipEarned',{cosmeticId=id}) end,cosmetic.color)
     T.button(body,'Nameplate • '..cosmetic.name,function() deps.request('profileSetFrame',{frameId=id}) end,T.cream)
    end
   end
   T.button(body,'Classic flag & nameplate',function() deps.request('profileEquipEarned',{cosmeticId=''});deps.request('profileSetFrame',{frameId=''}) end,T.cream)
   for _,r in d.successfulRuns do row('RECENT SUMMIT • '..r.route,string.format('%dm %02ds',math.floor(r.elapsedSeconds/60),r.elapsedSeconds%60)) end
   for _,a in A.titles do
    local unlocked=d.titles[a.id];T.button(body,(unlocked and 'Equip: ' or 'Locked: ')..a.name..' • '..(a.summits and (a.summits..' summits') or (a.percent..'% collection')),function() if unlocked then deps.request('profileSelectTitle',{titleId=a.id}) end end,unlocked and T.gold or T.cream)
   end
   row('CHOOSE UP TO THREE', 'Tap owned creatures to add or remove them from your public showcase.')
   for _,b in d.selectable do
    T.button(body,(table.find(self.selected,b.creatureId) and '✓ ' or '+ ')..b.name,function()
     local i=table.find(self.selected,b.creatureId);if i then table.remove(self.selected,i) elseif #self.selected<3 then table.insert(self.selected,b.creatureId) end
     deps.request('profileSetShowcase',{creatureIds=table.clone(self.selected)})
    end)
   end
   T.button(body,'Open full Collection',function() self.close();deps.collection() end,T.teal)
  end
  if card.userId==game.Players.LocalPlayer.UserId then T.button(body,self.showDetails and 'Hide private details' or 'Your private details & selections',function() self.showDetails=not self.showDetails;self.draw() end,T.teal) end
 end
 function self.open(card,details)
  self.generation=(self.generation or 0)+1;deps.closeOthers();previous=GS.SelectedObject;self.card=card;self.details=details;self.showDetails=false;root.Visible=true;deps.modal(true);self.draw();GS.SelectedObject=close
 end
 function self.updateOwner(st)
  self.owner=st.profile;self.ownerDetails=st.profileDetails
  if st.profile then self.selected={};for _,b in st.profile.showcase do table.insert(self.selected,b.creatureId) end end
  local signature=game.HttpService:JSONEncode({st.profile,st.profileDetails})
  if signature~=self.signature and root.Visible and self.card and self.card.userId==game.Players.LocalPlayer.UserId then local scroll=body.CanvasPosition;self.card=st.profile;self.details=st.profileDetails;self.draw();body.CanvasPosition=scroll end
  self.signature=signature
 end
 function self.isOpen() return root.Visible end
 function self.own() if self.owner then self.open(self.owner,self.ownerDetails) end end
 function self.unavailable(message) self.card=nil;self.message=message;self.draw() end
 CAS:BindActionAtPriority('CC_ProfileClose',function(_,s) if not root.Visible then return Enum.ContextActionResult.Pass end;if s==Enum.UserInputState.Begin then self.close() end;return Enum.ContextActionResult.Sink end,false,3400,Enum.KeyCode.ButtonB,Enum.KeyCode.Escape)
 function self.destroy() self.close();CAS:UnbindAction('CC_ProfileClose');root:Destroy() end
 return self
end
return U
