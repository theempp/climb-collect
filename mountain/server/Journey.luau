-- Travel never banks new runs. Confirmation is scoped to the current run identity.
local J={}
function J.new(context)
 local busy={}
 local service={}
 function service.go(player,destination,abandonRunId)
  if busy[player] or type(destination)~='string' then return false end
  local p=context.profile(player)
  if not p or not context.ready(player) or not context.origin(player,destination) then return false end
  local target=context.resolve(player,destination)
  if not target then return false end
  if p.run then
   if abandonRunId~=p.run.id then return false,'abandon_confirmation_required',p.run.id end
   if not context.forfeit or not context.forfeit(player,'travel') then return false,'forfeit_unavailable' end
   p=context.profile(player)
   if not p or p.run or not context.ready(player) or not context.origin(player,destination) then return false end
  elseif abandonRunId then return false,'confirmation_expired' end
  busy[player]=true
  local ok,moved=pcall(context.move,player,target)
  busy[player]=nil
  if not ok or moved~=true then return false end
  if p.schema==1 then context.extract(p) end -- pre-migration test/legacy compatibility only
  context.arrived(player,target)
  return true
 end
 return service
end
return J
