local A=require('../shared/Analytics')
local C=require('../shared/LiveConfig')
local S=require('../shared/Sfx')
local Cat=require('../shared/Catalog')
local n=0
local function check(v,msg) assert(v,msg);n+=1 end

-- Analytics -------------------------------------------------------------
local calls,t={},0
local svc={}
for _,m in {'LogCustomEvent','LogOnboardingFunnelStepEvent','LogFunnelStepEvent','LogProgressionStartEvent',
 'LogProgressionCompleteEvent','LogProgressionFailEvent','LogEconomyEvent'} do
 svc[m]=function(_,...) table.insert(calls,{m,...}) end
end
local warns=0
local a=A.new({service=svc,now=function() return t end,ccu=function() return 0 end,warn=function() warns+=1 end})
check(a.custom('P','hatch',1,{area='blossom',device='phone',context='rare'}),'known event logs')
check(calls[1][1]=='LogCustomEvent' and calls[1][3]=='hatch' and calls[1][5].context=='rare','event args pass through')
check(not a.custom('P','typed by player'),'unknown event refused')
check(#calls==1 and warns==1,'refused event never reaches the service')
a.custom('P','fall',1,{area='Bob the climber',context='fall'})
check(calls[2][5].area=='other','free text in a field becomes other')
check(a.funnel('P','shop','s1',2,'item_viewed') and calls[3][1]=='LogFunnelStepEvent' and calls[3][4]=='s1','funnel signature order')
check(not a.funnel('P','nope','s',1,'x'),'unknown funnel refused')
check(a.onboarding('P',3,'egg_spotted') and calls[4][3]==3,'onboarding step')
check(a.progression('P','complete','kingdoms',2,'azure') and calls[5][1]=='LogProgressionCompleteEvent','progression complete')
check(a.economy('P','Source','Coins',50,150,'bank','') and calls[6][3]=='Source' and calls[6][7]=='bank','economy event')
check(not a.economy('P','Source','Gems',1,1,'bank'),'unknown currency refused')
for _,k in Cat.kingdoms do check(A.FIELDS.area[k.id],'area enum covers kingdom '..k.id) end
-- rate limit: ccu 0 -> 120*.8 = 96 per minute
check(A.budget(0)==96 and A.budget(8)==224,'budget formula 120+20xCCU at 80%')
local before=#calls
for _=1,200 do a.custom('P','perf_sample') end
check(a.used==96 and a.dropped>0,'calls above the per-minute budget are dropped')
t+=61;check(a.custom('P','perf_sample'),'budget resets after a minute')
-- faults never escape
local bad=A.new({service={LogCustomEvent=function() error('boom') end},now=function() return 0 end,warn=function() end})
check(bad.custom('P','alert')==false and bad.failed==1,'service error is caught')
check(A.new({now=function() return 0 end}).custom('P','alert')==false,'missing service is a no-op')
-- aggregation
calls={}
local g=A.new({service=svc,now=function() return 0 end})
for _=1,5 do g.count('error_count',1,{context='save'}) end
g.count('error_count',2,{context='error'})
check(g.flush('P')==2 and #calls==2,'counters flush once per key')
local total=0;for _,c in calls do total+=c[4] end
check(total==7,'counter sums kept')
check(g.flush('P')==0,'flush empties counters')

-- LiveConfig -------------------------------------------------------------
local d=C.defaults()
check(d['shop.enabled']==true and d['economy.coinMultCap']==100 and d['hatch.floorSeconds']==60,'defaults')
for _,k in Cat.kingdoms do check(C.SCHEMA['mountain.'..k.id],'kingdom switch '..k.id) end
check(C.SCHEMA['party.enabled']==nil and C.SCHEMA['season.enabled']==nil,'dropped v1 features have no flags')
local remote,fetchFails={version=1,values={['shop.ladders']=false}},false
local changed={}
local lc=C.new({fetch=function() if fetchFails then error('down') end return remote end,warn=function() end})
lc.onChanged(function(k,v) changed[k]=v end)
check(lc.refresh()=='applied' and lc.get('shop.ladders')==false and changed['shop.ladders']==false,'flag applies and notifies')
check(lc.refresh()=='same','same version ignored')
remote={version=2,values={['economy.coinRate']=1e9}}
check(lc.refresh()=='rejected' and lc.get('economy.coinRate')==1 and lc.version==1,'out-of-range rejected, last good kept')
remote={version=3,values={['shop.enabled']='no'}}
check(lc.refresh()=='rejected','wrong type rejected')
remote={version=3,values={['shopp.enabled']=false}}
check(lc.refresh()=='rejected','typo key rejected')
remote={version=3,values={banner='hello players'}}
check(lc.refresh()=='rejected','banner only from preset keys')
remote={version=3,values={banner='maintenance',['economy.coinMultCap']=50}}
check(lc.refresh()=='applied' and lc.get('banner')=='maintenance' and lc.get('shop.ladders')==true,'new version replaces whole config')
remote={version=2,values={['shop.enabled']=false}}
check(lc.refresh()=='same' and lc.get('shop.enabled')==true,'older version never rolls back')
fetchFails=true
check(lc.refresh()=='fetch_failed' and lc.get('economy.coinMultCap')==50,'fetch failure keeps last good')
check(not pcall(lc.get,'nope'),'unknown key errors loudly')
local pv=lc.publicView()
check(pv['shop.enabled']==true and pv['economy.coinRate']==nil and pv.banner=='maintenance','clients see flags, not tunables')
check(not C.validate({values={}}),'missing version rejected')
check(not C.validate({version=1,values={['economy.xpRate']=0/0}}),'NaN rejected')

-- Sfx -------------------------------------------------------------------
local st={phone=true,haptics=true}
local now,started,buzz=0,{},{}
local sx=S.new({now=function() return now end,settings=function() return st end,
 play=function(name) table.insert(started,name);return {} end,haptic=function(v) table.insert(buzz,v) end})
for name,c in S.CUES do
 check(S.GROUPS[c.group] and c.volume>0 and c.volume<=1 and c.cooldown>0 and c.id==0,'cue '..name..' valid and unsourced')
 if c.haptic then check(S.HAPTIC_STRENGTH[c.haptic],'haptic level '..name) end
end
check(sx.play('egg_strike')==false and #started==0 and buzz[1]==.25,'id 0 stays silent but haptic still fires')
S.CUES.egg_strike.id=123
now=1;check(sx.play('egg_strike') and started[1]=='egg_strike','sourced cue plays')
check(not sx.play('egg_strike'),'cooldown blocks spam')
now=2;st.reduceEffects=true;local nb=#buzz
sx.play('egg_strike');check(#buzz==nb,'reduce effects blocks haptics')
st.reduceEffects=false;st.haptics=false;now=3;sx.play('egg_strike');check(#buzz==nb,'haptics toggle off')
st.haptics=true;st.phone=false;now=4;sx.play('egg_strike');check(#buzz==nb,'no haptics off phone')
st.low=true;sx.active=12;now=5
check(not sx.play('egg_strike'),'LOW graphics concurrency cap')
st.low=false;check(sx.play('egg_strike'),'normal cap is higher');sx.active=24;now=6
check(not sx.play('egg_strike'),'hard cap 24')
sx.ended();now=7;check(sx.play('egg_strike'),'ended frees a slot')
check(not sx.play('not_a_cue'),'unknown cue ignored')
local bad2=S.new({now=function() return 0 end,play=function() error('load failed') end})
check(bad2.play('egg_strike')==false,'play failure never throws')
S.CUES.egg_strike.id=0
check(S.hatchCue('Rare')=='hatch_reveal_rare' and S.hatchCue('Common')=='hatch_reveal','rare+ gets the bigger sting')
check(S.ladderCue(5)=='ladder_step_big' and S.ladderCue(2)=='ladder_step','x16/x32 steps get the big sting')

print('PASS '..n..' prelaunch service checks')
