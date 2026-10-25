local S={}
function S.new(capacity)
 local owners,slots,preferred={},{},{}
 local service={}
 function service.plot(uid,session)
  local owner=owners[uid]
  return if owner and owner.session==session then owner.slot else nil
 end
 function service.reserve(uid,session)
  if type(uid)~='number' or uid~=uid or math.abs(uid)==math.huge or uid%1~=0 or uid==0 or session==nil then return nil end
  local owner=owners[uid]
  if owner then return if owner.session==session then owner.slot else nil end
  local slot=preferred[uid]
  if not slot or slots[slot] then
   slot=nil
   for i=1,capacity do if not slots[i] then slot=i;break end end
  end
  if not slot then return nil end
  slots[slot]=uid;owners[uid]={slot=slot,session=session};preferred[uid]=slot
  return slot
 end
 function service.release(uid,session)
  local slot=service.plot(uid,session)
  if slot then slots[slot]=nil;owners[uid]=nil end
 end
 return service
end
return S
