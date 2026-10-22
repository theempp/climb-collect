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
  local rarity=T.panel(body,'RarityFieldGuide',T.cream);rarity.Size=UDim2.new(1,-8,0,130)
  local rarityColors={T.teal,Color3.fromRGB(111,187,105),Color3.fromRGB(91,160,225),T.purple,T.gold}
  for i,name in {'Common','Uncommon','Rare','Epic','Legendary'} do
   local count=card.collection.byRarity[name]
   local cell=T.make('Frame',rarity,{BackgroundTransparency=1,Position=UDim2.new((i-1)/5,4,0,6),Size=UDim2.new(1/5,-8,1,-12)})
   local icon=T.make('Frame',cell,{Size=UDim2.fromOffset(20,20),Position=UDim2.new(.5,-10,0,4),Rotation=45,BackgroundColor3=rarityColors[i],BorderSizePixel=0});T.make('UIStroke',icon,{Color=T.ink,Thickness=2})
   local label=T.text(cell,name,14);label.TextXAlignment=Enum.TextXAlignment.Center;label.Position=UDim2.new(0,0,0,30);label.Size=UDim2.new(1,0,0,34)
   local value=T.text(cell,count.collected..' / '..count.obtainable,17);value.TextXAlignment=Enum.TextXAlignment.Center;value.Position=UDim2.new(0,0,0,66);value.Size=UDim2.new(1,0,0,30)
   local bar=T.make('Frame',cell,{Position=UDim2.new(0,5,1,-8),Size=UDim2.new(1,-10,0,6),BackgroundColor3=Color3.fromRGB(216,211,183),BorderSizePixel=0});T.make('UICorner',bar,{CornerRadius=UDim.new(1,0)})
   local fill=T.make('Frame',bar,{Size=UDim2.fromScale(count.obtainable>0 and count.collected/count.obtainable or 0,1),BackgroundColor3=rarityColors[i],BorderSizePixel=0});T.make('UICorner',fill,{CornerRadius=UDim.new(1,0)})
  end
  local companion=row('ADVENTURE COMPANION',card.companion and (card.companion.name..' • '..card.companion.rarity..(card.companion.mutation and card.companion.mutation~='Normal' and (' • '..card.companion.mutation) or '')) or 'Choose your travelling companion at home.',T.teal)
  if card.companion then local portrait=T.creature(companion,card.companion.species);if portrait then portrait.Position=UDim2.fromOffset(6,6);for _,label in companion:GetChildren() do if label:IsA('TextLabel') then label.Position+=UDim2.fromOffset(90,0);label.Size-=UDim2.fromOffset(90,0) end end end end
  local showcase=T.make('Frame',body,{Name='SpecimenShowcase',BackgroundTransparency=1,Size=UDim2.new(1,-8,0,230),LayoutOrder=#body:GetChildren()})
  for i=1,3 do
   local b=card.showcase[i];local cell=T.panel(showcase,'Specimen'..i,Color3.fromRGB(255,231,167));cell.Position=UDim2.new((i-1)/3,4,0,0);cell.Size=UDim2.new(1/3,-8,1,0)
   local number=T.text(cell,'FIELD PICK 0'..i,13);number.Position=UDim2.fromOffset(8,6);number.Size=UDim2.new(1,-16,0,30);number.TextXAlignment=Enum.TextXAlignment.Center
   if b then local art=T.creature(cell,b.species);if art then art.Position=UDim2.new(.5,-45,0,40) end
   else local art=T.mountain(cell);art.Position=UDim2.new(.5,-50,0,50);art.ImageTransparency=.55 end
   local name=T.text(cell,b and b.name or 'Your next favourite',17);name.TextXAlignment=Enum.TextXAlignment.Center;name.Position=UDim2.new(0,8,0,136);name.Size=UDim2.new(1,-16,0,54)
   local note=T.text(cell,b and (b.rarity..(b.mutation and b.mutation~='Normal' and (' • '..b.mutation) or '')) or 'OPEN SHOWCASE',13);note.Font=Enum.Font.GothamBold;note.TextXAlignment=Enum.TextXAlignment.Center;note.Position=UDim2.new(0,8,0,192);note.Size=UDim2.new(1,-16,0,32)
   T.fitText(name,54);T.fitText(note,32)
   local function fitSpecimen()
    note.Position=UDim2.fromOffset(8,136+name.Size.Y.Offset+2)
    local needed=note.Position.Y.Offset+note.Size.Y.Offset+10
    if showcase.Size.Y.Offset<needed then showcase.Size=UDim2.new(1,-8,0,needed) end
   end
   name:GetPropertyChangedSignal('Size'):Connect(fitSpecimen);note:GetPropertyChangedSignal('Size'):Connect(fitSpecimen);task.defer(fitSpecimen)
  end
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
