-- Same-server travel: resolve and move before extracting; no profile schema changes.
local J={}
function J.new(context)
 local busy={}
 local service={}
 function service.go(player,destination)
  if busy[player] or type(destination)~='string' then return false end
  local p=context.profile(player)
  if not p or not context.ready(player) or not context.origin(player,destination) then return false end
  local target=context.resolve(player,destination)
  if not target then return false end
  busy[player]=true
  local ok,moved=pcall(context.move,player,target)
  busy[player]=nil
  if not ok or moved~=true then return false end
  context.extract(p)
  context.arrived(player,target)
  return true
 end
 return service
end
return J
