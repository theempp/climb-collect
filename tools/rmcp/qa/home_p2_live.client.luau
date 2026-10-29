-- Home-base P2 live QA (Client, Play): real correlated requests through MountainRemotes.UIRequest on a fresh
-- Studio-memory profile (rank 1, 0 coins). Records each reply and the coins seen in state events.
local RS=game:GetService('ReplicatedStorage');local Players=game:GetService('Players')
local remotes=RS:WaitForChild('MountainRemotes');local req,res,ev=remotes.UIRequest,remotes.UIResult,remotes.Event
local replies={};local coins=nil;local home=nil;local seq=0;local plot=nil;local atHome=nil
local c1=res.OnClientEvent:Connect(function(r) replies[r.id]=r end)
local function scan(t,depth) if type(t)~='table' or depth>3 then return end
 if type(t.coins)=='number' and t.creatures then coins=t.coins end
 if type(t.home)=='table' and t.home.tier then home=t.home end
 if type(t.plot)=='number' and t.atHome~=nil then plot=t.plot;atHome=t.atHome end
 for _,v in pairs(t) do scan(v,depth+1) end end
local c2=ev.OnClientEvent:Connect(function(kind,data) scan(data,0) end)
local function call(action,payload,wait)
 seq+=1;local id='qa:'..seq;req:FireServer(id,action,payload)
 local t=os.clock();while not replies[id] and os.clock()-t<15 do task.wait(.05) end
 task.wait(wait or .35)
 local r=replies[id];return {action=action,payload=payload,ok=r and r.ok,message=r and r.message,data=r and r.data,coins=coins}
end
local log={}
local function step(name,action,payload,wait) local r=call(action,payload,wait);r.name=name;table.insert(log,r);return r end
call('State',nil)
local start=coins
step('tier below rank','Home',{op='tier'})
step('tier payload with tier field','Home',{op='tier',tier=4})
step('prop with 0 coins','Home',{op='place',slot=1,kind='prop',id='bed'})
step('tier-2 prop at tier 1','Home',{op='place',slot=1,kind='prop',id='lantern'})
step('slot 5 locked at tier 1','Home',{op='place',slot=5,kind='creature',id='c1'})
step('unowned creature','Home',{op='place',slot=1,kind='creature',id='c999'})
step('place c1 on slot 1','Home',{op='place',slot=1,kind='creature',id='c1'})
step('c1 again on slot 2','Home',{op='place',slot=2,kind='creature',id='c1'})
step('occupied slot 1','Home',{op='place',slot=1,kind='creature',id='c2'})
step('assign displayed c1 to habitat','Tycoon',{op='assign',slot=1,id='c1'})
step('inspect own decor 1','Inspect',{plot=plot or 1,kind='decor',index=1},.6)
step('clear slot 1','Home',{op='clear',slot=1})
step('clear slot 1 again','Home',{op='clear',slot=1})
step('comfort upgrade with 0 coins','Tycoon',{op='upgrade',path='habitat',slot=1})
step('habitat module with 0 coins','Tycoon',{op='upgrade',path='habitats'})
step('inspect bad index','Inspect',{plot=1,kind='habitat',index=7},.6)
c1:Disconnect();c2:Disconnect()
local out={startCoins=start,endCoins=coins,home=home,plot=plot,atHome=atHome,steps={}}
for _,r in ipairs(log) do table.insert(out.steps,{name=r.name,ok=r.ok,message=r.message,coins=r.coins,decor1=r.data and r.data.home and r.data.home.decor and r.data.home.decor[1] or nil,inspect=r.data and r.data.inspect}) end
return game:GetService('HttpService'):JSONEncode(out)
