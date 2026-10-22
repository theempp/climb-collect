local R={target=7,reviewEconomy=true}
function R.dayKey(epoch) assert(type(epoch)=='number' and epoch==epoch and math.abs(epoch)<1e12,'invalid epoch');return math.floor(epoch/86400) end
function R.descriptor(day)
 local index=day%3+1;local sequences={{1,2},{1,2,3},{1,2,3,2,3}};local sections={}
 for _,i in sequences[index] do table.insert(sections,'Practice:'..i) end
 return {id='circuit'..index,sections=sections,resetAt=(day+1)*86400}
end
function R.default() return {lastCreditedDay=-1,stamps=0,milestoneGranted=false,bestByChallenge={}} end
function R.clean(v)
 local d=R.default();if type(v)~='table' then return d end
 local function finite(n) return type(n)=='number' and n==n and math.abs(n)<1e12 end
 d.lastCreditedDay=finite(v.lastCreditedDay) and math.floor(v.lastCreditedDay) or -1
 d.stamps=finite(v.stamps) and math.clamp(math.floor(v.stamps),0,7) or 0;d.milestoneGranted=v.milestoneGranted==true
 for i=1,3 do local id='circuit'..i;local t=type(v.bestByChallenge)=='table' and v.bestByChallenge[id];if finite(t) and t>0 then d.bestByChallenge[id]=t end end
 return d
end
function R.advance(a,id,inside)
 if not inside or a.sections[a.next]~=id then return false end
 a.next+=1;return true
end
function R.credit(data,day,config)
 data.dailyPractice=data.dailyPractice or R.default();local d=data.dailyPractice
 if day<=d.lastCreditedDay then return {ok=true,credited=false,stamps=d.stamps} end
 d.lastCreditedDay=day;d.stamps=math.min(config.target,d.stamps+1)
 local grant=d.stamps>=config.target and not d.milestoneGranted
 if grant then d.milestoneGranted=true;data.expedition.earnedCosmetics=data.expedition.earnedCosmetics or {};data.expedition.earnedCosmetics.practice_pennant=true end
 return {ok=true,credited=true,stamps=d.stamps,milestoneGranted=grant}
end
return R
