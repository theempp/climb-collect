-- Typed hud raid events (C18, C20): one event per transition, drops consumed before adopt, toasts unchanged.
local now=100;local serial=0;local function guid() serial+=1;return 'id'..serial end
local a={UserId=1,Parent=true};local b={UserId=2,Parent=true};local c={UserId=3,Parent=true}
local ps={[a]=Rules.newProfile(100),[b]=Rules.newProfile(100),[c]=Rules.newProfile(100)}
local alive={[a]=true,[b]=true,[c]=true};local exit=false
local roots={[a]={Position=v(0,0,0),CFrame={LookVector=v(1,0,0)}},[b]={Position=v(2,0,0),CFrame={LookVector=v(-1,0,0)}},[c]={Position=v(100,0,0),CFrame={LookVector=v(1,0,0)}}}
local huds,toasts={},{};local onChanged
local function hud(player,kind,data) table.insert(huds,{player=player,kind=kind,data=data}) end
local function count(player,kind,field,value) local k=0;for _,e in ipairs(huds) do if e.player==player and e.kind==kind and (field==nil or e.data[field]==value) then k+=1 end end;return k end
local function last(player,kind) for i=#huds,1,-1 do if huds[i].player==player and huds[i].kind==kind then return huds[i].data end end;return nil end
local function toastsFor(player) local list={};for _,t in ipairs(toasts) do if t.player==player then table.insert(list,t.text) end end;return list end
local function same(x,y) if #x~=#y then return false end;for i=1,#x do if x[i]~=y[i] then return false end end;return true end
local visuals=CarryVisuals.new({},function(player,kind,text) if kind=='toast' then table.insert(toasts,{player=player,text=text}) end end,hud)
local profiles={get=function(p) return ps[p] end,pending=function() return false end,transact=function(p,_,fn) return fn(ps[p]) end}
-- Strike visuals need Studio art; every other present kind runs through the real CarryVisuals.
local raids=EggRaids.new({profiles=profiles,clock=function() return now end,guid=guid,eggs={n={id='n',section=1,species='mossbun',position=v(0,0,0)}},
 alive=function(p) return alive[p] end,near=function() return true end,atExit=function() return exit end,changed=function(p) if onChanged then onChanged(p) end end,
 present=function(p,data) if data.kind~='strike' then visuals.show(p,data) end end})
local bats=Bats.new({profile=profiles.get,root=function(p) return roots[p] end,alive=function(p) return alive[p] end,clock=function() return now end,
 players=function() return {a,b,c} end,guid=guid,raids=raids,protected=raids.protected,folder={},safeZone=function() return false end,
 knock=function() end,notify=function(p,text) table.insert(toasts,{player=p,text=text}) end,hud=hud})
local function carry(player)
 for _=1,10 do now+=1;raids.strike(player,'n');if ps[player].run.phase=='revealed' then break end end
 return raids.pickup(player,ps[player].run.id)
end
local name=Catalog.byId.mossbun.name
check(carry(a),'fresh_pickup')
local e=last(a,'carry');check(count(a,'carry')==1 and e.species=='mossbun' and e.section==1 and e.runId==ps[a].run.id and e.trial==false and e.stolen==nil,'fresh_pickup_sends_one_carry')
local ok,result=bats.swing(b);check(ok and result=='hit' and not ps[a].run,'carrier_knocked')
local knocked=last(a,'knocked')
check(knocked and knocked.species=='mossbun' and knocked.expiresAt==1000+BatRules.dropSeconds and knocked.by==b.UserId and type(knocked.dropId)=='string','knocked_uses_server_clock_expiry')
check(count(a,'lost')==0,'bat_drop_is_not_a_loss')
-- Two grabs of one drop in the same frame: the second runs inside the first adopt window and must find it consumed.
local inner
onChanged=function(p) if p==b and inner==nil then inner={bats.grab(a,knocked.dropId)} end end
check(bats.grab(b,knocked.dropId),'thief_grabs');onChanged=nil
check(inner and inner[1]==false and inner[2]=='gone','same_frame_second_grab_finds_drop_consumed')
check(ps[b].run and not ps[a].run,'same_frame_double_grab_exactly_one_carrier')
e=last(b,'carry');check(count(b,'carry')==1 and e.stolen==true and e.runId==ps[b].run.id and count(b,'regrab')==0,'thief_gets_one_stolen_carry_no_regrab')
check(count(a,'lost','reason','stolen')==1 and last(a,'lost').species=='mossbun','victim_gets_lost_stolen')
local again={bats.grab(a,knocked.dropId)};check(again[1]==false and again[2]=='gone','later_grab_finds_drop_gone')
now+=2;ok,result=bats.swing(a);check(result=='hit' and not ps[b].run,'thief_knocked')
local drop2=last(b,'knocked').dropId
ps[c].run={id='crun',eggId='x',species='petalyn',section=1,trial=false,phase='carried',hits=0,startedAt=now};roots[c].Position=v(2,0,0)
ok,result=bats.grab(c,drop2);check(not ok and result=='full_hands' and ps[c].run.id=='crun' and not ps[b].run,'full_hands_grab_refused')
roots[c].Position=v(100,0,0)
local carries=count(b,'carry')
check(bats.grab(b,drop2) and ps[b].run,'drop_restored_after_failed_adopt')
e=last(b,'regrab');check(count(b,'regrab')==1 and e.auto==nil and e.runId==ps[b].run.id and count(b,'carry')==carries,'regrab_without_double_carry')
now+=10;ok,result=bats.swing(a);check(result=='hit','hit_after_victim_cooldown')
local drop3=last(b,'knocked').dropId;local reentrant
onChanged=function(p) if p==b and reentrant==nil then reentrant={bats.grab(a,drop3)} end end
now+=BatRules.dropSeconds;bats.tick(now);onChanged=nil
check(ps[b].run and not ps[a].run and reentrant and reentrant[2]=='gone','auto_return_consumes_drop_before_adopt')
check(count(b,'regrab','auto',true)==1 and count(b,'carry')==carries,'auto_regrab_event_without_carry')
now+=10;bats.swing(a);alive[b]=false;now+=BatRules.dropSeconds;bats.tick(now);alive[b]=true
check(not ps[b].run and count(b,'lost','reason','escaped')==1 and count(b,'regrab','auto',true)==1,'escaped_drop_sends_lost')
bats.tick(now+10);check(count(b,'lost')==1,'escaped_drop_sent_once')
check(same(toastsFor(a),{'Knocked! Your '..name..' dropped — grab it back!','Your creature was taken. Unsecured creatures stay at risk until the sanctuary gate.',
 'Hit! Grab the '..name..' before it escapes.','Hit! Grab the '..name..' before it escapes.','Hit! Grab the '..name..' before it escapes.'}),'carrier_toasts_byte_identical')
check(same(toastsFor(b),{'Hit! Grab the '..name..' before it escapes.','Knocked! Your '..name..' dropped — grab it back!','Knocked! Your '..name..' dropped — grab it back!',
 'Knocked! Your '..name..' dropped — grab it back!','Your dropped creature escaped.'}),'thief_toasts_byte_identical')
now+=30;check(carry(a),'second_pickup');raids.forfeit(a,'fall')
local list=toastsFor(a)
check(count(a,'lost','reason','fall')==1 and last(a,'lost').eggId=='n' and list[#list]=='Unsecured '..name..' lost. Try another egg.','forfeit_sends_lost_and_same_toast')
now+=30;check(carry(a),'third_pickup');local runId=ps[a].run.id
exit=true;check(raids.exit(a,runId),'secured');exit=false
list=toastsFor(a)
check(count(a,'safe')==1 and last(a,'safe').runId==runId and last(a,'safe').species=='mossbun','safe_event')
check(list[#list-1]=='Securing your creature… You are protected while saving.' and list[#list]=='Safe! '..name..' is yours. Carry it home.','securing_and_safe_toasts_unchanged')
check(count(a,'carry')==3 and count(a,'regrab')==0,'one_carry_per_fresh_pickup')
print('PASS '..checks..' raid hud event checks')
