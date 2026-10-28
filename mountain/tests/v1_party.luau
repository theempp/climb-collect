-- C01-C02: duo max, invite/friend/code, ready-check travel, leader handoff, stale invites, disconnect, follow.
local P=require('../shared/PartyRules')
local Service=require('../server/PartyService')
local V=require('../shared/V1Config')
local n=0
local function check(v,name) assert(v,name);n+=1 end
local reg=P.new(99)
local ok,party=P.create(reg,1,0)
check(ok and party.leader==1 and #party.code==V.party.codeLength and not party.code:find('[0OIL1]'),'create_with_code')
check(not P.create(reg,1,0),'one_party_per_user')
check(P.invite(reg,1,2,0),'invite')
check(not P.invite(reg,1,1,0) and not P.invite(reg,1,'x',0),'invalid_targets')
check(not P.accept(reg,3,party.id,0),'accept_requires_invite')
check(P.accept(reg,2,party.id,10) and #party.members==2,'accept_joins')
check(not P.invite(reg,1,3,10),'max_two_invite')
check(not P.invite(reg,2,3,10),'member_cannot_invite')
local _,p2=P.create(reg,3,10);check(not P.joinCode(reg,3,party.code,10),'already_in_party_cannot_join')
P.leave(reg,3,10);check(reg.parties[p2.id]==nil,'solo_leave_dissolves')
check(not P.joinCode(reg,4,party.code,10),'code_full')
-- stale invites
local reg2=P.new(1);local _,q=P.create(reg2,10,0);P.invite(reg2,10,11,0)
check(not P.accept(reg2,11,q.id,V.party.inviteSeconds+1),'expired_invite_rejected')
P.invite(reg2,10,12,0);local ev=P.tick(reg2,V.party.inviteSeconds+1);check(#ev==1 and ev[1].kind=='invite_expired' and next(reg2.invites)==nil,'tick_purges_stale')
P.invite(reg2,10,13,0);P.leave(reg2,10,1);check(next(reg2.invites)==nil and reg2.parties[q.id]==nil,'leader_leaving_alone_purges_invites')
-- code join is case-insensitive, friend join
local reg3=P.new(5);local _,r=P.create(reg3,20,0)
check(P.joinCode(reg3,21,string.lower(r.code),0),'code_case_insensitive')
P.leave(reg3,21,0);check(P.joinFriend(reg3,22,20,0) and #r.members==2,'friend_join')
check(not P.joinFriend(reg3,23,99,0),'friend_must_be_in_party')
-- ready check
check(not P.startReady(reg3,22,0),'member_cannot_start_ready')
check(P.startReady(reg3,20,0) and r.state=='ready_check','leader_starts_ready')
check(not P.joinCode(reg3,24,r.code,0),'no_join_during_ready')
check(#P.tick(reg3,1)==0,'waits_for_member')
P.setReady(reg3,22,true,2);local t=P.tick(reg3,2)
check(#t==1 and t[1].kind=='travel' and #t[1].travelers==2 and t[1].complete and r.state=='departed','all_ready_travel_together')
check(not P.canFollow(reg3,22,3),'traveler_cannot_follow')
-- partial ready: leader travels solo, member may follow for 2 minutes
P.reset(reg3,r.id);P.startReady(reg3,20,100)
local t2=P.tick(reg3,100+V.party.readySeconds+1)
check(#t2==1 and #t2[1].travelers==1 and t2[1].travelers[1]==20 and not t2[1].complete,'expired_ready_leader_continues_solo')
check(P.canFollow(reg3,22,130),'late_follow_window')
check(not P.canFollow(reg3,22,100+V.party.readySeconds+1+V.party.followSeconds+1),'follow_expires')
-- leader leaves: remaining member becomes leader; ready check cancelled
P.reset(reg3,r.id);P.startReady(reg3,20,500)
local okL,info=P.leave(reg3,20,501);check(okL and info.leader==22 and r.leader==22 and r.state=='idle' and r.ready==nil,'leader_handoff_and_cancel')
check(not P.setReady(reg3,22,true,502),'ready_mark_after_cancel_rejected')
check(P.kick(reg3,22,22,0)==false and P.kick(reg3,20,22,0)==false,'kick_rules')
-- service: travel through deps, notifications, disconnect, follow, cross-server code
local players={};local notes={};local travelled={};local followed={};local tracked={}
local function mk(id) local pl={UserId=id,Name='u'..id};players[id]=pl;return pl end
local a,b,c=mk(101),mk(102),mk(103)
local clock=0
local teleports={}
local directory={data={}}
directory.publish=function(code,data) directory.data[code]=data end
directory.lookup=function(code) return directory.data[code] end
directory.remove=function(code) directory.data[code]=nil end
local svc=Service.new({clock=function() return clock end,player=function(id) return players[id] end,travel=function(pl) table.insert(travelled,pl.UserId);return true end,
 follow=function(pl,leader) table.insert(followed,{pl.UserId,leader.UserId});return true end,notify=function(pl,kind,data) table.insert(notes,{pl.UserId,kind,data}) end,
 isFriend=function(x,y) return (x==103 and y==101) end,directory=directory,teleport=function(pl,job,data) table.insert(teleports,{pl.UserId,job,data});return true end,jobId='jobA',
 track=function(pl,event,amount) table.insert(tracked,{pl.UserId,event,amount}) end})
check(svc.request(a,'invite',{userId=102}),'svc_invite')
check(not svc.request(a,'invite',{userId=999}),'svc_invite_requires_target_present')
local partyId=svc.registry.byUser[101]
check(svc.request(b,'accept',{partyId=partyId}) and #svc.state(a).party.members==2,'svc_accept')
check(not svc.request(c,'friend',{userId=102}),'svc_friend_check_server_side')
check(svc.request(a,'ready_start',{}) and svc.request(b,'ready',{ready=true}),'svc_ready')
svc.tick();check(#travelled==2 and #tracked==2 and tracked[1][2]=='party_expedition','svc_travel_both_and_track')
local lastParty;for _,nn in ipairs(notes) do if nn[2]=='party' and nn[1]==102 then lastParty=nn[3] end end
check(lastParty and lastParty.party.state=='departed','svc_notifies_members')
svc.returned(a);check(svc.state(a).party.state=='idle','svc_return_resets')
-- disconnect mid ready check: other member stays, can travel solo
svc.request(a,'ready_start',{});svc.remove(b);players[102]=nil
check(#svc.state(a).party.members==1 and svc.state(a).party.state=='idle','svc_disconnect_recovery')
check(svc.request(a,'ready_start',{}),'svc_solo_ready_after_disconnect');svc.tick()
check(#travelled==3,'svc_solo_travel')
-- cross-server code: unknown here -> teleport to the leader's server from the directory
directory.data['ZZZZZZ']={jobId='jobB',leader=555,size=1}
local okT,msg=svc.request(c,'code',{code='zzzzzz'});check(okT and msg=='teleporting' and teleports[1][2]=='jobB' and teleports[1][3].partyCode=='ZZZZZZ','svc_cross_server_code_teleport')
directory.data['FULLFU']={jobId='jobC',size=2};check(not svc.request(c,'code',{code='FULLFU'}),'svc_cross_server_full')
directory.data['SAMEJB']={jobId='jobA',size=1};check(not svc.request(c,'code',{code='SAMEJB'}),'svc_stale_directory_same_job')
-- arrival with teleport data joins
local code=svc.state(a).party.code
check(svc.arrived(c,{partyCode=code}) and #svc.state(a).party.members==2,'svc_arrival_joins')
check(not svc.arrived(c,{partyCode=string.rep('A',50)}),'svc_arrival_bounds')
check(#svc.mates(a)==1 and svc.mates(a)[1]==c,'svc_mates')
svc.request(a,'leave',{});svc.request(c,'leave',{});check(directory.data[code]==nil,'svc_dissolve_removes_directory_code')
print('PASS '..n..' party checks')
