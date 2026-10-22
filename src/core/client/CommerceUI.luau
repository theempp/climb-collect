-- Foothold Exchange: one responsive sheet inside the existing Expedition modal owner.
local Players,Market,GuiService,UIS=game:GetService("Players"),game:GetService("MarketplaceService"),game:GetService("GuiService"),game:GetService("UserInputService")
local C,Art=require(script.Parent.Parent.CommerceConfig),require(script.Parent.Parent.CommerceArt)
local plr=Players.LocalPlayer
local U={};local opt,root,shell,body,heading,wallet,nav,closeButton,hud,shopButton
local render,fit
local state,sections,labels={}, {}, {}
local prices=require(script.Parent.CommercePrices).new(C,function(o)
 local v=Market:GetProductInfoAsync(o.platformId,o.kind=="pass" and Enum.InfoType.GamePass or Enum.InfoType.Product)
 return v.IsForSale~=false and v.PriceInRobux or nil
end)
local refreshing=false
local function refreshPrices()
 if refreshing then return end;refreshing=true
 task.spawn(function()
  local changed=false
  for _,id in ipairs(C.order) do local old=prices:get(id);local new=prices:refresh(id);changed=changed or old~=new end
  refreshing=false
  if changed and shell and shell.Visible then render() end
 end)
end
local selected,reveal,seen,previousFocus=nil,nil,{},nil
local lastSignature=""
local purple,deep,gold,green,ink=Color3.fromRGB(84,43,133),Color3.fromRGB(48,25,83),Color3.fromRGB(255,211,97),Color3.fromRGB(143,226,86),Color3.fromRGB(42,30,60)
local function make(class,parent,p)
 local x=Instance.new(class);for k,v in pairs(p or {}) do x[k]=v end;x.Parent=parent;return x
end
local function round(x,r) make("UICorner",x,{CornerRadius=UDim.new(0,r or 12)}) end
local function border(x,color,n) make("UIStroke",x,{Color=color or gold,Thickness=n or 2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local function panel(parent,name,color,x,y,w,h)
 local f=make("Frame",parent,{Name=name,BackgroundColor3=color,BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h)});round(f);return f
end
local function gradient(x,top,bottom) make("UIGradient",x,{Color=ColorSequence.new(top,bottom),Rotation=90}) end
local function text(parent,name,value,x,y,w,h,size,color)
 return make("TextLabel",parent,{Name=name,Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=math.floor((size or 16)*((state.settings or {}).textScale or 1)),TextColor3=color or ink,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
end
local function button(parent,name,value,x,y,w,h,fn,color)
 local b=make("TextButton",parent,{Name=name,Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color or green,TextColor3=ink,TextSize=math.floor(15*((state.settings or {}).textScale or 1)),TextWrapped=true,Font=Enum.Font.GothamBold,BorderSizePixel=0,AutoButtonColor=true,Selectable=true})
 round(b,9);border(b,Color3.fromRGB(235,255,196),1.5)
 b.Activated:Connect(fn);return b
end
local function picture(parent,id,x,y,w,h)
 local v=make("ViewportFrame",parent,{Name="Artwork",Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,Ambient=Color3.fromRGB(125,125,140),LightColor=Color3.fromRGB(220,210,195),LightDirection=Vector3.new(-1,-2,-3)})
 local m=Art.make(id,v);local cf,sz=m:GetBoundingBox();local camera=Instance.new("Camera");camera.FieldOfView=30;camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(-0.5,0.5,-math.max(sz.Y,sz.X/(w/h))*2.2),cf.Position);camera.Parent=v;v.CurrentCamera=camera
 if id:match("^upgrade") then
  local label=text(v,"TierArtwork",((tonumber(id:match("%d+")) or 0)+1)*2 .."×",w*0.26,h*0.2,w*0.48,h*0.4,24,ink);label.TextXAlignment=Enum.TextXAlignment.Center;label.TextScaled=true
 end
 return v
end
local function offer(id) return state.commerce and state.commerce.offers[id] or {status="unavailable"} end
local function price(id)
 return prices:get(id)
end
local function priceText(id)
 local o=C.offers[id]
 if o.platformId==0 then return o.draftPrice.." Robux · draft" end
 return price(id) and (price(id).." Robux") or "Price unavailable"
end
local function caption(id)
 local s=offer(id)
 if s.status=="owned" then return "✓ OWNED" elseif s.status=="partial" then return "View missing item →" elseif s.status=="pending" then return "Owned · needs earlier tiers" elseif s.status=="locked" then return "Unlock previous tier" end
 return priceText(id)
end
local function choose(id) selected=id;reveal=nil;render(true) end
local function card(id,x,y,w,h,warm,horizontal)
 local o=C.offers[id];local color=warm and Color3.fromRGB(255,209,111) or ({Color3.fromRGB(170,224,246),Color3.fromRGB(206,177,245),Color3.fromRGB(192,233,148),Color3.fromRGB(248,182,215)})[(#id%4)+1]
 local f=panel(body,"Offer_"..id,color,x,y,w,h);border(f,warm and gold or Color3.fromRGB(236,219,255),2)
 gradient(f,warm and Color3.fromRGB(255,231,153) or color,warm and Color3.fromRGB(246,177,62) or color:Lerp(Color3.new(1,1,1),0.16))
 local left=horizontal and math.min(160,w*0.28) or 0
 picture(f,id,horizontal and 8 or w*0.18,horizontal and 8 or (warm and 90 or 32),horizontal and left-12 or w*0.64,horizontal and h-16 or math.max(70,h-(warm and 216 or 170)))
 text(f,"Name",warm and "CAMP GLOW" or o.name,horizontal and left+10 or 12,horizontal and 2 or (warm and 38 or h-132),horizontal and w-left-24 or w-24,42,warm and 24 or 17)
 if warm and not horizontal then
  local a,b,c=price("bundle"),price("lantern"),price("banner")
  local savings=a and b and c and b+c>a and math.floor((1-a/(b+c))*100)
  text(f,"Badge",savings and (savings.."% less than separate items") or "TWO PERMANENT COSMETICS",horizontal and left+10 or 12,horizontal and -2 or 6,horizontal and w-left-24 or w-24,25,11)
 end
 text(f,"Detail",warm and "Sunbeam lantern skin + camp banner" or o.coins and "Exact amount · never multiplied" or o.tier and "Permanent total earnings" or "Yours on every expedition",horizontal and left+10 or 12,horizontal and 44 or h-85,horizontal and w-left-24 or w-24,horizontal and 30 or 24,12)
 button(f,"View_"..id,caption(id),horizontal and left+10 or 12,horizontal and h-48 or h-55,horizontal and w-left-24 or w-24,44,function() choose(id) end)
end
local function nextId()
 local c=state.commerce or {tier=0,owned={}}
 return c.tier<6 and "upgrade"..c.tier or not c.owned.flag and "flag" or not c.owned.trail and "trail" or "coins100"
end
local function headingAt(name,title,y,w)
 sections[name]=y;text(body,name,title,4,y,w-8,34,21,gold);return y+42
end
local function catalogue(w,compact)
 local y=compact and 0 or headingAt("Featured","Pack a little sunshine.",4,w)
 sections.Featured=0
 local scale=(state.settings or {}).textScale or 1
 local ch=scale>1.1 and 260 or 240
 if compact then
  card("bundle",0,y,w,124,true,true);y+=136
  for i,id in ipairs({nextId(),"coins2000","flag","trail"}) do local col=(i-1)%2;card(id,col*(w+12)/2,y+math.floor((i-1)/2)*(ch+12),(w-12)/2,ch);end;y+=2*(ch+12)
 else
  local hero=w*0.43;card("bundle",0,y,hero,2*ch+12,true,false)
  for i,id in ipairs({nextId(),"coins2000","flag","trail"}) do card(id,hero+12+((i-1)%2)*(w-hero)/2,y+math.floor((i-1)/2)*(ch+12),(w-hero-36)/2,ch) end;y+=2*ch+26
 end
 y=headingAt("Upgrades","↗ A permanent step up.",y,w)
 text(body,"TierNote","Total multipliers · next tier only · purchased packs excluded",0,y,w,40,14,Color3.fromRGB(235,224,250));y+=48
 local cols=w<700 and 3 or 6;local cell=(w-(cols-1)*10)/cols
 for i,n in ipairs(C.tiers) do
  local id="upgrade"..(i-1);local f=panel(body,"Tier_"..i,offer(id).status=="next" and Color3.fromRGB(169,220,124) or Color3.fromRGB(115,77,159),((i-1)%cols)*(cell+10),y+math.floor((i-1)/cols)*172,cell,162)
  text(f,"Multiplier",n.."×",10,4,cell-20,44,30,gold)
  text(f,"TierPrice",priceText(id),8,50,cell-16,40,12,Color3.new(1,1,1))
  button(f,"TierAction",offer(id).status=="next" and "View upgrade" or offer(id).status=="pending" and "Prerequisites" or offer(id).status=="owned" and "Owned" or "Locked",8,102,cell-16,50,function() choose(id) end)
 end
 y+=math.ceil(6/cols)*172+8
 y=headingAt("Coins","● A few coins for home.",y,w)
 local best,bestRatio=nil,0
 for _,n in ipairs({100,350,900,2000}) do local p=price("coins"..n);if p and p>0 and n/p>bestRatio then bestRatio=n/p;best="coins"..n end end
 text(body,"CoinNote",best and ("Best coins / Robux: "..C.offers[best].name..string.format(" · %.2f",bestRatio)) or "Guaranteed exact amounts. You can always keep earning by playing.",0,y,w,42,14,Color3.new(1,1,1));y+=50
 cols=compact and 2 or 4;cell=(w-(cols-1)*12)/cols
 for i,n in ipairs({100,350,900,2000}) do card("coins"..n,((i-1)%cols)*(cell+12),y+math.floor((i-1)/cols)*(ch+12),cell,ch) end;y+=math.ceil(4/cols)*(ch+12)+8
 y=headingAt("Cosmetics","Make the trail your own.",y,w)
 for i,id in ipairs({"flag","trail","lantern","banner"}) do card(id,((i-1)%cols)*(cell+12),y+math.floor((i-1)/cols)*(ch+12),cell,ch) end;y+=math.ceil(4/cols)*(ch+12)
 text(body,"EarnedOnly","Summit Points are earned only. Every item shown is guaranteed; cosmetics do not change gameplay.",0,y,w,54,14,Color3.fromRGB(235,224,250));return y+64
end
local function detail(w)
 local id=selected;local o=C.offers[id];if not o then return 0 end
 local s=offer(id);local compact=w<740;local y=0
 button(body,"Back","← All offers",0,0,150,44,function() selected=nil;render(true) end,Color3.fromRGB(198,176,236))
 picture(body,id,0,56,compact and 140 or 220,190)
 local x=compact and 152 or 236;local tw=w-x
 text(body,"ProductTitle",o.name,x,54,tw,65,26,gold)
 text(body,"ProductDescription",o.detail,x,122,tw,110,15,Color3.new(1,1,1));y=254
 local message=s.status=="pending" and ("This pass is owned. Activate the earlier tiers starting at "..((state.commerce.tier+1)*2).."× first.") or s.status=="locked" and "Complete the previous tier before this upgrade." or s.status=="partial" and "You own part of Camp Glow. Choose only the missing item." or s.status=="owned" and "Already yours. Equip your cosmetics below." or "Roblox confirms the current price and available payment options. Cancelling keeps this offer selected."
 text(body,"OwnershipMessage",message,4,y,w-8,64,16,gold);y+=76
 if s.status=="partial" then button(body,"MissingItem","View "..C.offers[s.missingItem].name,0,y,w,50,function() choose(s.missingItem) end);y+=62
 elseif s.status=="available" or s.status=="next" then
  local enabled=o.platformId>0 and price(id)~=nil and state.saveState=="ok" and not state.commerce.checkout
  local b=button(body,"NativeCheckout",enabled and ("Continue to Roblox · "..priceText(id)) or (o.platformId==0 and ("Checkout unavailable · "..priceText(id)) or state.commerce.checkout and "Waiting for Roblox…" or "Price or save unavailable"),0,y,w,56,function() if enabled then opt.request("commercePurchase",{offerId=id}) end end)
  b.AutoButtonColor=enabled;b.Active=enabled;b.Selectable=enabled;b.BackgroundColor3=enabled and green or Color3.fromRGB(177,164,194);y+=68
 end
 for _,item in ipairs(o.items or {}) do
  if state.commerce.owned[item] then local equipped=state.commerce.equipped[item];button(body,"Equip_"..item,(equipped and "Unequip " or "Equip ")..C.offers[item].name,0,y,w,50,function() opt.request("commerceEquip",{id=item,enabled=not equipped}) end);y+=62 end
 end
 button(body,"KeepExploring","Keep exploring",0,y,w,48,U.close,Color3.fromRGB(204,184,233));return y+60
end
local function reward(w)
 local o=C.offers[reveal.offerId];if not o then return 0 end
 text(body,"RewardTitle","A little more adventure.",0,0,w,55,28,gold)
 local pending=offer(reveal.offerId).status=="pending"
 text(body,"Confirmed",pending and "Pass saved. Earlier tiers are required before activation." or "It's yours! Every reward shown is guaranteed.",0,56,w,50,16,Color3.new(1,1,1))
 local ids=o.items or {reveal.offerId};local cell=(w-12*(#ids-1))/#ids
 for i,id in ipairs(ids) do
  local f=panel(body,"Reward_"..id,Color3.fromRGB(145,89,190),(i-1)*(cell+12),116,cell,250);border(f)
  picture(f,id,10,8,cell-20,156);text(f,"RewardName",C.offers[id].name,12,168,cell-24,48,19,gold)
  text(f,"Permanent",o.coins and "EXACT AMOUNT ADDED" or "PERMANENT · YOURS TO KEEP",12,216,cell-24,28,11,Color3.new(1,1,1))
 end
 button(body,"RevealDone","Back to the adventure",0,380,w,52,U.dismiss);return 444
end
render=function(reset)
 if not body then return end
 local scroll=reset and 0 or body.CanvasPosition.Y
 local focus=GuiService.SelectedObject;local focusName=focus and focus.Name
 GuiService.SelectedObject=nil
 body:ClearAllChildren();sections={}
 local w=math.max(250,body.AbsoluteSize.X-12)
 local h=reveal and reward(w) or selected and detail(w) or catalogue(w,shell.AbsoluteSize.Y<500 or w<800)
 body.CanvasSize=UDim2.fromOffset(0,h);body.CanvasPosition=Vector2.new(0,scroll)
 for _,b in ipairs(nav:GetChildren()) do if b:IsA("GuiButton") then b.Visible=not selected and not reveal end end
 heading.Text=reveal and "YOUR REWARD" or "▲ FOOTHOLD EXCHANGE"
 wallet.Text=tostring(state.coins or 0).." coins  ·  "..tostring(state.commerce and state.commerce.multiplier or 1).."×"
 if focusName and shell.Visible then GuiService.SelectedObject=body:FindFirstChild(focusName,true) or closeButton end
end
fit=function()
 local s=root.AbsoluteSize;local w,h=math.min(1080,s.X-16),math.min(760,s.Y-12)
 shell.Size=UDim2.fromOffset(w,h);shell.Position=UDim2.fromOffset((s.X-w)/2,(s.Y-h)/2)
 local narrow=w<720
 heading.Size=UDim2.new(1,narrow and -70 or -290,0,52);heading.TextSize=math.floor((narrow and 18 or 25)*((state.settings or {}).textScale or 1))
 wallet.Visible=not narrow;wallet.Position=UDim2.new(1,-278,0,8);wallet.Size=UDim2.fromOffset(210,44)
 body.Position=UDim2.fromOffset(14,112);body.Size=UDim2.new(1,-28,1,-140)
 local cw=(w-28-18)/4
 for i,b in ipairs(nav:GetChildren()) do if b:IsA("GuiButton") then b.Position=UDim2.fromOffset((i-1)*(cw+6),0);b.Size=UDim2.fromOffset(cw,44) end end
 if hud then
  local phone=s.Y<500
  hud.Size=UDim2.fromOffset(phone and 138 or 134,phone and 48 or 56)
  hud.Position=phone and UDim2.new(0.5,0,1,-52) or UDim2.new(1,-10,0,184)
  hud.AnchorPoint=phone and Vector2.new(0.5,0) or Vector2.new(1,0)
  hud.First.Size=UDim2.fromOffset(phone and 138 or 134,phone and 48 or 56)
  hud.Second.Size=hud.First.Size;hud.Second.Position=UDim2.fromOffset(phone and 148 or 0,phone and 0 or 64)
  hud.Second.Visible=false -- one contextual offer plus the Shop entry
  shopButton.Size=UDim2.fromOffset(phone and 90 or 134,46)
  shopButton.Position=UDim2.new(1,-10,0,126)
 end
 if shell.Visible then render() end
end
function U.open(id)
 refreshPrices()
 if not opt.safe() then return end
 opt.closeOtherPanels();previousFocus=GuiService.SelectedObject
 hud.Visible=false;shopButton.Visible=false
 selected=id and C.offers[id] and id or nil;reveal=nil;shell.Visible=true;opt.onModalChanged(true);fit();render(true)
 GuiService.SelectedObject=closeButton
end
function U.dismiss()
 if reveal then local id=reveal.grantId;seen[id]=true;opt.request("commerceRevealAck",{grantId=id});reveal=nil end
 U.close()
end
function U.close()
 if not shell or not shell.Visible then return end
 shell.Visible=false;opt.onModalChanged(false)
 local valid=previousFocus and previousFocus.Parent and previousFocus:IsA("GuiObject") and previousFocus.Selectable
 local a=previousFocus;while valid and a do if a:IsA("GuiObject") and not a.Visible then valid=false end;a=a.Parent end
 GuiService.SelectedObject=valid and previousFocus or nil
end
function U.isOpen() return shell and shell.Visible end
function U.fx(p) if p.kind=="commerceOpen" then U.open(p.offerId) end end
function U.update(s)
 local old=state;state=s
 local signature=game:GetService("HttpService"):JSONEncode({s.commerce,s.coins,s.settings,s.saveState})
 if signature~=lastSignature and shell and shell.Visible then render() end
 lastSignature=signature
 for _,entry in pairs(labels) do if entry.gui.Parent then
  local id=entry.id=="next" and "upgrade"..math.min(s.commerce and s.commerce.tier or 0,5) or entry.id
  entry.text.Text=C.offers[id].name.."\n"..caption(id)
 end end
end
function U.tick()
 if not shell then return end
 local safe=opt.safe() and state.saveState=="ok"
 if shell.Visible and not safe then U.close() end
 hud.Visible=safe and not shell.Visible and not opt.otherOpen()
 shopButton.Visible=hud.Visible
 if hud.Visible then
  local first=nextId();local second=offer("bundle").status=="available" and "bundle" or "coins100"
  hud.First.Text=(C.offers[first].tier and C.offers[first].tier*2 .."× earnings" or C.offers[first].name).."\n"..caption(first);hud.Second.Text=C.offers[second].name.."\n"..caption(second)
  hud.First.TextSize=math.floor(12*((state.settings or {}).textScale or 1));hud.Second.TextSize=hud.First.TextSize
 end
 if safe and not shell.Visible and not opt.otherOpen() and state.commerce then
  for id,r in pairs(state.commerce.pendingReveals) do if not seen[id] then
   opt.closeOtherPanels();reveal=r;selected=nil;shell.Visible=true;opt.onModalChanged(true);fit();render(true);GuiService.SelectedObject=closeButton;break
  end end
 end
end
function U.init(options)
 opt=options
 root=make("Frame",opt.parent,{Name="CommerceRoot",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=60})
 shell=panel(root,"Exchange",purple,0,0,900,620);shell.Visible=false;shell.ClipsDescendants=true;border(shell,gold,3)
 local header=make("Frame",shell,{Name="GoldHeader",Size=UDim2.new(1,0,0,62),BackgroundColor3=gold,BorderSizePixel=0});gradient(header,Color3.fromRGB(255,237,162),Color3.fromRGB(241,181,48))
 heading=text(header,"Heading","▲ FOOTHOLD EXCHANGE",14,4,600,52,25)
 wallet=text(header,"Wallet","",0,8,210,44,16)
 closeButton=button(header,"CloseExchange","×",0,6,48,48,U.dismiss,Color3.fromRGB(240,121,166));closeButton.AnchorPoint=Vector2.new(1,0);closeButton.Position=UDim2.new(1,-8,0,6)
 nav=make("Frame",shell,{Name="Categories",Position=UDim2.fromOffset(14,66),Size=UDim2.new(1,-28,0,44),BackgroundTransparency=1})
 for i,n in ipairs({"Featured","Upgrades","Coins","Cosmetics"}) do button(nav,n,({"Featured","↗ Upgrades","● Coin packs","Cosmetics"})[i],0,0,150,44,function() body.CanvasPosition=Vector2.new(0,sections[n] or 0) end,Color3.fromRGB(179,145,218)) end
 body=make("ScrollingFrame",shell,{Name="Catalogue",BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,ScrollBarImageColor3=gold,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None})
 local footer=text(shell,"Footer","Guaranteed rewards · permanent cosmetics & upgrades",14,0,800,24,11,Color3.fromRGB(237,216,255));footer.Position=UDim2.new(0,14,1,-26);footer.Size=UDim2.new(1,-28,0,24)
 hud=panel(root,"Offers",deep,0,0,134,120);hud.AnchorPoint=Vector2.new(1,0);hud.Position=UDim2.new(1,-10,0,68);hud.BackgroundTransparency=1
 button(hud,"First","",0,0,134,56,function() U.open(nextId()) end,Color3.fromRGB(182,226,143))
 button(hud,"Second","",0,64,134,56,function() U.open(offer("bundle").status=="available" and "bundle" or "coins100") end,Color3.fromRGB(216,184,244))
 shopButton=button(root,"OpenShop","SHOP",0,0,134,46,function() U.open() end,gold);shopButton.AnchorPoint=Vector2.new(1,0);shopButton.Position=UDim2.new(1,-10,0,196)
 root:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not (state.commerce and state.commerce.checkout) and shell.Visible and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB) then U.dismiss() end
 end)
 task.spawn(function() while root.Parent do refreshPrices();task.wait(5) end end)
 local function display(m)
  if not m:IsA("Model") or not m:GetAttribute("CommerceOffer") or labels[m] then return end
  local p=m:FindFirstChild("Plinth");if not p then return end
  local g=make("BillboardGui",p,{Name="LocalCommerceLabel",Size=UDim2.fromOffset(240,72),StudsOffset=Vector3.new(0,4.6,0),MaxDistance=45,AlwaysOnTop=false})
  local l=text(g,"Label","",0,0,240,72,16,gold);l.TextXAlignment=Enum.TextXAlignment.Center;l.TextStrokeTransparency=0.3
  labels[m]={gui=g,text=l,id=m:GetAttribute("CommerceOffer")}
 end
 local world=workspace:WaitForChild("World");local displays=world:WaitForChild("CommerceDisplays",20)
 if displays then for _,m in ipairs(displays:GetChildren()) do display(m) end;displays.ChildAdded:Connect(function(m) task.defer(display,m) end) end
 if game:GetService("RunService"):IsStudio() then
  local bridge=make("BindableFunction",root,{Name="Review"})
  bridge.OnInvoke=function(action,value)
   if action=="open" then U.open(value) elseif action=="close" then U.dismiss()
   elseif action=="section" then selected=nil;reveal=nil;render(true);body.CanvasPosition=Vector2.new(0,sections[value] or 0)
   elseif action=="scroll" then body.CanvasPosition=Vector2.new(0,value) end
   local small,overflow,outside={},{},{}
   for _,v in ipairs(shell:GetDescendants()) do
    if v:IsA("GuiObject") then
     local visible=v.Visible;local a=v.Parent;while a and a~=root do if a:IsA("GuiObject") and not a.Visible then visible=false end;a=a.Parent end
     local p,z=v.AbsolutePosition,v.AbsoluteSize;local bp,bz=body.AbsolutePosition,body.AbsoluteSize
     local inView=visible and not v:FindFirstAncestorWhichIsA("SurfaceGui") and p.Y+z.Y>bp.Y and p.Y<bp.Y+bz.Y
     if inView and v:IsA("GuiButton") and (z.X<44 or z.Y<44) then table.insert(small,v.Name) end
     if inView and (v:IsA("TextLabel") or v:IsA("TextButton")) and (v.TextBounds.X>z.X+1 or v.TextBounds.Y>z.Y+1) then table.insert(overflow,v.Name) end
     if inView and (p.X<shell.AbsolutePosition.X-1 or p.X+z.X>shell.AbsolutePosition.X+shell.AbsoluteSize.X+1) then table.insert(outside,v.Name) end
    end
   end
   return {viewport=tostring(root.AbsoluteSize),shop=tostring(shell.AbsoluteSize),small=small,overflow=overflow,outside=outside,scroll=body.CanvasPosition.Y,canvas=body.AbsoluteCanvasSize.Y,view=body.AbsoluteSize.Y,selected=selected,reveal=reveal and reveal.offerId}
  end
 end
 fit()
end
return U
