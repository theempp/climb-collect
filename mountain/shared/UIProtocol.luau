-- Shared wire validation only; all ownership, proximity and costs remain server rules.
local U={}
local actions={Strike=true,Pickup=true,PutDown=true,Tycoon=true,State=true,Equip=true,Train=true,Specialize=true,Incubate=true,Hatch=true,Travel=true,TravelAbandon=true,CollectIncome=true,RegisterDefense=true,ChallengeDefense=true,Special=true,Dodge=true,Settings=true,Swing=true,Bat=true,Home=true,Inspect=true}
local defaults={reducedMotion=false,largeText=false,highContrast=false,simplifiedVFX=false,musicVolume=.7,sfxVolume=.8,hints=true}
local function finite(value) return type(value)=='number' and value==value and math.abs(value)<math.huge end
local function text(value) return type(value)=='string' and #value>0 and #value<=80 end
local function fields(value,allowed)
 if type(value)~='table' then return false end
 for key in pairs(value) do if not allowed[key] then return false end end
 return true
end
function U.parseId(id)
 if type(id)~='string' or #id>64 then return nil end
 local token,sequence=id:match('^([%w_%-]+):(%d+)$')
 if not token or #token>48 or #sequence>15 or sequence:sub(1,1)=='0' then return nil end
 local n=tonumber(sequence)
 if not n or n<1 or n>9007199254740991 then return nil end
 return token,n
end
function U.settings(patch,current)
 local result=table.clone(defaults)
 if type(current)=='table' then
  for key,default in pairs(defaults) do
   local value=current[key]
   if type(value)==type(default) and (type(value)~='number' or (finite(value) and value>=0 and value<=1)) then result[key]=value end
  end
 end
 if patch==nil then return result end
 if type(patch)~='table' then return nil end
 for key,value in pairs(patch) do
  local default=defaults[key]
  if default==nil or type(value)~=type(default) or (type(value)=='number' and (not finite(value) or value<0 or value>1)) then return nil end
  result[key]=value
 end
 return result
end
function U.validate(id,action,payload)
 if not U.parseId(id) then return false,'Invalid request id.' end
 if type(action)~='string' or not actions[action] then return false,'Unknown action.' end
 local valid=false
 if action=='PutDown' then valid=payload==nil
 elseif action=='TravelAbandon' then valid=fields(payload,{destination=true,runId=true}) and text(payload.destination) and text(payload.runId)
 elseif action=='Strike' or action=='Pickup' then valid=text(payload)
 elseif action=='Tycoon' then
  local function slot(v,zero) return finite(v) and v%1==0 and v>=(if zero then 0 else 1) and v<=8 end
  if type(payload)=='table' then
   if payload.op=='bank' then valid=fields(payload,{op=true})
   elseif payload.op=='collect' then valid=fields(payload,{op=true,slot=true}) and slot(payload.slot,true)
   elseif payload.op=='assign' then valid=fields(payload,{op=true,slot=true,id=true}) and slot(payload.slot,false) and (payload.id==nil or text(payload.id))
   elseif payload.op=='swap' then valid=fields(payload,{op=true,slot=true,other=true}) and slot(payload.slot,false) and slot(payload.other,false) and payload.slot~=payload.other
   elseif payload.op=='attune' then valid=fields(payload,{op=true,slot=true,kingdom=true}) and slot(payload.slot,false) and finite(payload.kingdom) and payload.kingdom%1==0 and payload.kingdom>=1 and payload.kingdom<=6
   elseif payload.op=='cosmetic' then valid=fields(payload,{op=true,id=true}) and text(payload.id)
   elseif payload.op=='upgrade' then valid=fields(payload,{op=true,path=true,slot=true}) and table.find({'habitats','habitat','production','storage','bag','banking','automation'},payload.path)~=nil and (if payload.path=='habitat' then slot(payload.slot,false) else payload.slot==nil) end
  end
 elseif action=='Home' then
  if type(payload)=='table' then
   if payload.op=='buy' then valid=fields(payload,{op=true,item=true}) and text(payload.item)
   elseif payload.op=='place' then valid=fields(payload,{op=true,slot=true,item=true}) and text(payload.slot) and text(payload.item)
   elseif payload.op=='clear' then valid=fields(payload,{op=true,slot=true}) and text(payload.slot)
   elseif payload.op=='showcase' then valid=fields(payload,{op=true,slot=true,id=true}) and text(payload.slot) and (payload.id==nil or text(payload.id)) end
  end
 elseif action=='Inspect' then
  valid=fields(payload,{plot=true,kind=true,key=true}) and finite(payload.plot) and payload.plot%1==0 and payload.plot>=1 and payload.plot<=8
   and (payload.kind=='habitat' or payload.kind=='display') and ((payload.kind=='habitat' and finite(payload.key) and payload.key%1==0 and payload.key>=1 and payload.key<=8) or (payload.kind=='display' and text(payload.key)))
 elseif action=='Bat' then valid=fields(payload,{op=true,id=true}) and (payload.op=='equip' or payload.op=='upgrade') and text(payload.id)
 elseif action=='State' or action=='Swing' or action=='Dodge' or action=='CollectIncome' or action=='RegisterDefense' then valid=payload==nil
 elseif action=='Train' or action=='Incubate' or action=='Hatch' or action=='Travel' then valid=text(payload)
 elseif action=='ChallengeDefense' then valid=finite(payload) and payload%1==0 and payload>=0 and payload<=9007199254740991
 elseif action=='Settings' then valid=payload~=nil and U.settings(payload)~=nil
 elseif action=='Specialize' then valid=fields(payload,{id=true,choice=true}) and text(payload.id) and table.find({'Power','Guard','Vitality'},payload.choice)~=nil
 elseif action=='Special' then valid=fields(payload,{slot=true,ability=true}) and finite(payload.slot) and payload.slot%1==0 and payload.slot>=1 and payload.slot<=3 and (payload.ability==nil or (finite(payload.ability) and payload.ability%1==0 and payload.ability>=1 and payload.ability<=4))
 elseif action=='Equip' and type(payload)=='table' and #payload>=1 and #payload<=3 then
  valid=true;local seen={}
  for key,value in pairs(payload) do
   if not finite(key) or key%1~=0 or key<1 or key>#payload or not text(value) or seen[value] then valid=false;break end
   seen[value]=true
  end
 end
 return valid,if valid then nil else 'Invalid action payload.'
end
return U
