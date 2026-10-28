-- C01-C02 duo parties: pure registry for one server. Max 2 (LOCKED). Invite / friend / code join,
-- leader ready-check, departure, late follow window (PROPOSED 2 min), leave and disconnect recovery.
-- Users are numeric UserIds. Every function returns ok, reason|data; nothing yields.
local Config=if script then require(script.Parent.V1Config) else require('./V1Config')
local P={}
local alphabet='ABCDEFGHJKMNPQRSTUVWXYZ23456789' -- no 0/O/1/I/L
function P.new(seed) return {parties={},byUser={},invites={},codes={},serial=0,seed=seed or 1} end
local function code(reg,partyId)
 local h=reg.seed
 for attempt=1,50 do
  local s,x='',(h+partyId*7919+attempt*104729)%2147483647
  for _=1,Config.party.codeLength do x=(x*48271)%2147483647;local i=x%#alphabet+1;s..=alphabet:sub(i,i) end
  if not reg.codes[s] then return s end
 end
 return nil
end
local function snapshot(party)
 if not party then return nil end
 local members={};for _,id in ipairs(party.members) do table.insert(members,id) end
 local ready={};if party.ready then for id in pairs(party.ready.marks) do table.insert(ready,id) end;table.sort(ready) end
 return {id=party.id,leader=party.leader,members=members,code=party.code,state=party.state,
  readyExpires=party.ready and party.ready.expires or nil,ready=ready,departedAt=party.departedAt,travelers=party.travelers}
end
P.snapshot=snapshot
function P.partyOf(reg,user) local id=reg.byUser[user];return id and reg.parties[id] end
function P.create(reg,leader,now)
 if reg.byUser[leader] then return false,'already_in_party' end
 reg.serial+=1
 local c=code(reg,reg.serial);if not c then return false,'code_unavailable' end
 local party={id=reg.serial,leader=leader,members={leader},code=c,state='idle',createdAt=now}
 reg.parties[party.id]=party;reg.byUser[leader]=party.id;reg.codes[c]=party.id
 return true,party
end
local function join(reg,party,user,now)
 if reg.byUser[user] then return false,'already_in_party' end
 if #party.members>=Config.party.maxSize then return false,'party_full' end
 if party.state=='ready_check' then return false,'ready_check_running' end
 table.insert(party.members,user);reg.byUser[user]=party.id
 for key,inv in pairs(reg.invites) do if inv.target==user then reg.invites[key]=nil end end
 return true,party
end
function P.invite(reg,from,target,now)
 if type(target)~='number' or target==from then return false,'invalid_target' end
 local party=P.partyOf(reg,from)
 if not party then local ok,res=P.create(reg,from,now);if not ok then return false,res end;party=res end
 if party.leader~=from then return false,'not_leader' end
 if #party.members>=Config.party.maxSize then return false,'party_full' end
 if reg.byUser[target] then return false,'target_in_party' end
 local key=party.id..':'..target
 reg.invites[key]={party=party.id,from=from,target=target,expires=now+Config.party.inviteSeconds}
 return true,{partyId=party.id,target=target,expires=now+Config.party.inviteSeconds}
end
function P.accept(reg,user,partyId,now)
 local key=tostring(partyId)..':'..tostring(user);local inv=reg.invites[key]
 if not inv then return false,'no_invite' end
 reg.invites[key]=nil
 if now>inv.expires then return false,'invite_expired' end
 local party=reg.parties[inv.party];if not party then return false,'party_gone' end
 return join(reg,party,user,now)
end
function P.decline(reg,user,partyId)
 local key=tostring(partyId)..':'..tostring(user)
 if not reg.invites[key] then return false,'no_invite' end
 reg.invites[key]=nil;return true
end
function P.joinCode(reg,user,c,now)
 if type(c)~='string' then return false,'invalid_code' end
 local party=reg.parties[reg.codes[string.upper(c)] or -1]
 if not party then return false,'code_not_here' end
 return join(reg,party,user,now)
end
-- Friends may join without an invite (decision: invite / friends / code). Caller verifies friendship.
function P.joinFriend(reg,user,friend,now)
 local party=P.partyOf(reg,friend);if not party then return false,'friend_not_in_party' end
 return join(reg,party,user,now)
end
local function dissolve(reg,party)
 for _,id in ipairs(party.members) do reg.byUser[id]=nil end
 reg.codes[party.code]=nil;reg.parties[party.id]=nil
 for key,inv in pairs(reg.invites) do if inv.party==party.id then reg.invites[key]=nil end end
end
-- Leave or disconnect. The remaining member keeps the party (and becomes leader); a party of one that has
-- not departed stays open for a new invite. Pending invites from/to the user are purged.
function P.leave(reg,user,now)
 for key,inv in pairs(reg.invites) do if inv.target==user or inv.from==user then reg.invites[key]=nil end end
 local party=P.partyOf(reg,user);if not party then return false,'not_in_party' end
 local i=table.find(party.members,user);table.remove(party.members,i);reg.byUser[user]=nil
 if party.ready then party.ready=nil;party.state='idle' end
 if party.travelers then local t=table.find(party.travelers,user);if t then table.remove(party.travelers,t) end end
 if #party.members==0 then dissolve(reg,party);return true,{dissolved=true} end
 if party.leader==user then party.leader=party.members[1] end
 return true,{party=party.id,leader=party.leader}
end
function P.kick(reg,leader,target,now)
 local party=P.partyOf(reg,leader)
 if not party or party.leader~=leader then return false,'not_leader' end
 if target==leader or not table.find(party.members,target) then return false,'invalid_target' end
 return P.leave(reg,target,now)
end
function P.startReady(reg,leader,now)
 local party=P.partyOf(reg,leader)
 if not party or party.leader~=leader then return false,'not_leader' end
 if party.state=='ready_check' then return false,'ready_check_running' end
 party.state='ready_check';party.ready={expires=now+Config.party.readySeconds,marks={[leader]=true}}
 return true,party
end
function P.setReady(reg,user,ready,now)
 local party=P.partyOf(reg,user)
 if not party or party.state~='ready_check' or not party.ready then return false,'no_ready_check' end
 if now>party.ready.expires then return false,'ready_check_expired' end
 party.ready.marks[user]=if ready then true else nil
 return true,party
end
-- Resolves ready checks. Everyone ready -> 'travel' with all members. Expired -> ready members travel,
-- the others may follow within the follow window (owner: if one leaves, the other continues solo).
function P.tick(reg,now)
 local events={}
 for key,inv in pairs(reg.invites) do if now>inv.expires then reg.invites[key]=nil;table.insert(events,{kind='invite_expired',target=inv.target,from=inv.from}) end end
 for _,party in pairs(reg.parties) do
  if party.state=='ready_check' and party.ready then
   local all=true;for _,id in ipairs(party.members) do if not party.ready.marks[id] then all=false end end
   if all or now>party.ready.expires then
    local travelers={};for _,id in ipairs(party.members) do if party.ready.marks[id] then table.insert(travelers,id) end end
    party.ready=nil;party.state='departed';party.departedAt=now;party.travelers=travelers
    table.insert(events,{kind='travel',party=party.id,travelers=travelers,complete=all})
   end
  end
 end
 return events
end
function P.canFollow(reg,user,now)
 local party=P.partyOf(reg,user)
 if not party or party.state~='departed' or not party.departedAt then return false,'nothing_to_follow' end
 if table.find(party.travelers,user) then return false,'already_traveled' end
 if now>party.departedAt+Config.party.followSeconds then return false,'follow_expired' end
 return true,party
end
function P.followed(reg,user)
 local party=P.partyOf(reg,user);if party and party.travelers and not table.find(party.travelers,user) then table.insert(party.travelers,user) end
end
-- After returning to the sanctuary the party can ready-check again.
function P.reset(reg,partyId)
 local party=reg.parties[partyId];if party then party.state='idle';party.departedAt=nil;party.travelers=nil;party.ready=nil end
end
function P.mates(reg,user)
 local party=P.partyOf(reg,user);local list={}
 if party then for _,id in ipairs(party.members) do if id~=user then table.insert(list,id) end end end
 return list
end
return P
