-- Disposable real Studio server and two actual client DataModels. Fixture placement is explicit.
local Players=game.Players;local STS=game:GetService('StudioTestService');local H=game.HttpService
local report={kind='actual Studio two-client network test; positions and summit eligibility are fixtures',checks={}}
local rpc=Instance.new('RemoteFunction');rpc.Name='PolishMultiplayerRPC';rpc.Parent=game.ReplicatedStorage
local function check(name,value,detail) table.insert(report.checks,{name=name,pass=value==true,detail=detail}) end
local function call(p,a,v) local r=rpc:InvokeClient(p,a,v);return r.ok and r.value or nil,r end
local function move(p,pos)
 game.ServerStorage.CC_CheckpointAPI.AuthorizeMove:Invoke(p,pos,'multiplayerFixture');p.Character:PivotTo(CFrame.new(pos));p.Character.HumanoidRootPart.Anchored=true
end
task.delay(150,function() pcall(function()STS:EndTest({timeout=true,report=report})end) end)
local ok,err=pcall(function()
 local deadline=os.clock()+70;repeat task.wait(.2) until #Players:GetPlayers()>=2 or os.clock()>deadline
 assert(#Players:GetPlayers()==2,'two actual clients did not join')
 local a,b=table.unpack(Players:GetPlayers());report.players={a.Name,b.Name}
 for _,p in {a,b} do
  repeat task.wait(.1) until p.Character and p.Character:FindFirstChild('HumanoidRootPart')
 end
 task.wait(8)
 local ra=call(a,'ready');local rb=call(b,'ready');check('independent client DataModels',ra and rb and ra.client and rb.client and ra.userId~=rb.userId,{ra,rb})
 move(a,Vector3.new(0,52,2070));move(b,Vector3.new(10,52,2070));task.wait(2)
 local tags=call(a,'view',b.UserId);check('nearby visible tag',tags and #tags>=1,tags)
 local card=call(a,'inspect',b.UserId);check('network public profile',card and card.status=='ok',card)
 local private=false;for _,k in {'cargo','coins','commerce','transactions','failures','profileDetails'} do if card and card.card and card.card[k]~=nil then private=true end end;check('public response excludes private fields',not private)
 local click,detail=call(a,'clickTag');check('actual virtual mouse tag click opens portfolio',click and click.open==true,detail)
 call(a,'close');local r3,r3detail=call(a,'r3');check('virtual R3 opens nearby portfolio',r3==true,r3detail);call(a,'close')
 local wall=Instance.new('Part');wall.Name='OcclusionFixture';wall.Anchored=true;wall.CanCollide=false;wall.Size=Vector3.new(14,20,1);wall.CFrame=CFrame.new(8,58,2076);wall.Parent=workspace
 tags=call(a,'view',b.UserId);check('opaque noncolliding prop blocks tags',tags and #tags==0,tags);wall:Destroy()
 move(b,Vector3.new(40,52,2070));task.wait(.5);card=call(a,'inspect',b.UserId);check('server range rejection',card and card.status=='outOfRange',card)
 move(a,Vector3.new(-227,52,1812));move(b,Vector3.new(-217,52,1812));task.wait(.5);card=call(a,'inspect',b.UserId);check('unsafe route rejection',card and card.status=='unsafe',card)
 for _,p in {a,b} do p.Character.HumanoidRootPart.Anchored=false;game.ServerStorage.CC_SummitReview:Invoke('fixture',p) end
 task.wait(4)
 local sa=call(a,'snapshot');local sb=call(b,'snapshot');check('simultaneous independent scenes',sa and sb and sa.scene and sb.scene,{sa,sb})
 sa=call(a,'space');sb=call(b,'snapshot');check('one player skip does not stop other scene',sa and sb and not sa.scene and sb.scene,{sa,sb});check('skip removes input binding',sa and not sa.skipBound,sa)
 task.wait(17);sa=call(a,'snapshot');sb=call(b,'snapshot');check('both scenes clean up',sa and sb and not sa.scene and not sb.scene and not sa.skipBound and not sb.skipBound,{sa,sb})
 local pa=game.ServerStorage.CC_SummitReview:Invoke('profile',a);local pb=game.ServerStorage.CC_SummitReview:Invoke('profile',b)
 check('separate exactly-once completion markers',pa.completedThrough==pa.pendingResult.seq and pb.completedThrough==pb.pendingResult.seq and pa.pendingResult.rewards.coins==150 and pb.pendingResult.rewards.coins==150,{pa.completedThrough,pb.completedThrough})
 for _,p in {a,b} do local result=game.ServerStorage.CC_SummitReview:Invoke('profile',p).pendingResult;game.ServerStorage.CC_DevBridge:Invoke('request',{name=p.Name,action='summitReturn',payload={resultId=result.id}}) end
 task.wait(1);move(a,Vector3.new(0,52,2070));move(b,Vector3.new(10,52,2070));local departedId=b.UserId;call(b,'leave');task.wait(.5)
 card=call(a,'inspect',departedId);check('departed subject becomes unavailable',card and card.status=='unavailable',card)
 STS:AddPlayers(1);task.wait(12);local newcomer;for _,p in Players:GetPlayers() do if p~=a then newcomer=p end end
 check('actual client joins after departure',newcomer~=nil,newcomer and {name=newcomer.Name,id=newcomer.UserId,previousId=departedId})
 report.reconnectLimit='AddPlayers creates a new simulated identity; same-account network reconnect is not established.'
end)
report.error=not ok and tostring(err) or nil
local passed=0;for _,v in report.checks do if v.pass then passed+=1 end end;report.passed=passed;report.total=#report.checks
STS:EndTest(report)
