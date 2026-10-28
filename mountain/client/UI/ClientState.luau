-- Authoritative state and correlated intents. A timeout means unknown outcome;
-- it deliberately keeps the action locked until an acknowledgment arrives.
local ClientState = {}
local Store = {}
Store.__index = Store
local actions = {Strike=true,Pickup=true,PutDown=true,Tycoon=true,State=true,Equip=true,Train=true,Specialize=true,Incubate=true,Hatch=true,
 Travel=true,TravelAbandon=true,CollectIncome=true,RegisterDefense=true,ChallengeDefense=true,Special=true,Dodge=true,Settings=true,Swing=true,Bat=true}
local function finite(value)
 return type(value)=='number' and value==value and math.abs(value)<math.huge
end
local function copy(value,seen)
 if type(value)~='table' then return value end
 seen=seen or {};if seen[value] then return seen[value] end
 local clone={};seen[value]=clone
 for k,v in pairs(value) do clone[k]=copy(v,seen) end
 return clone
end
local function safeCall(fn,...)
 local ok,err=pcall(fn,...)
 if not ok and warn then warn('Mountain UI listener: '..tostring(err)) end
end
local function defaultRuntime()
 return {delay=task.delay,cancel=task.cancel,monotonic=os.clock,epoch=os.time,
  clock=function() return workspace:GetServerTimeNow() end,
  token=function() return game:GetService('HttpService'):GenerateGUID(false) end}
end
function Store:_emit(kind,payload)
 if self._destroyed then return end
 for token,fn in pairs(table.clone(self._listeners)) do
  if self._listeners[token] then safeCall(fn,kind,payload) end
 end
end
function Store:_cancel(record)
 if record.timer then
  pcall(self._runtime.cancel,record.timer)
  record.timer=nil
 end
end
function Store:_available()
 return self._eventRemote~=nil and self._requestRemote~=nil and self._resultRemote~=nil
end
function Store:_receive(kind,payload)
 if self._destroyed then return end
 if kind=='state' then
  if type(payload)~='table' then return end
  self.profile=payload
  local mono=self._runtime.monotonic()
  if finite(payload.serverNow) then self._epochOffset=payload.serverNow-mono end
  if type(payload.ui)=='table' and finite(payload.ui.serverClock) then self._clockOffset=payload.ui.serverClock-mono end
  self.status=if self:_available() then 'ready' else 'error'
 elseif kind=='production' then
  if not self.profile or type(payload)~='table' or type(payload.tycoon)~='table' or not finite(payload.coins) then return end
  self.profile=table.clone(self.profile);self.profile.tycoon=payload.tycoon;self.profile.coins=payload.coins
  if finite(payload.serverNow) then self._epochOffset=payload.serverNow-self._runtime.monotonic() end
 elseif kind=='battle' then
  if payload~=false and type(payload)~='table' then return end
  self.battle=payload
 elseif kind=='context' then
  if type(payload)~='table' or not self.profile then return end
  local ui=table.clone(self.profile.ui or {})
  for key,value in pairs(payload) do ui[key]=value end
  self.profile=table.clone(self.profile);self.profile.ui=ui
  if finite(payload.serverClock) then self._clockOffset=payload.serverClock-self._runtime.monotonic() end
 elseif kind~='open' and kind~='toast' and kind~='save' and kind~='hud' then return end
 self:_emit(kind,payload)
end
function Store:_result(result)
 if self._destroyed or type(result)~='table' or type(result.id)~='string' or type(result.ok)~='boolean' or type(result.message)~='string' then return end
 local record=self._requests[result.id]
 if not record or result.action~=record.action then return end
 self:_cancel(record)
 self._requests[result.id]=nil;self._byAction[record.action]=nil;self.pending[result.id]=nil
 local confirmed={id=result.id,action=result.action,ok=result.ok,message=result.message,data=result.data}
 self.lastResult=confirmed
 self._completed[result.id]=true;table.insert(self._history,result.id)
 if #self._history>64 then self._completed[table.remove(self._history,1)]=nil end
 if record.action=='State' and not self.profile then self.status='error' end
 self:_emit('pending',{id=record.id,action=record.action,status='complete'})
 self:_emit('result',confirmed)
 if record.callback and not self._destroyed then safeCall(record.callback,confirmed) end
end
function Store:_discover()
 if self._destroyed then return end
 local function child(name)
  if not self._remotes then return nil end
  return self._remotes:FindFirstChild(name)
 end
 local event,result,request=child('Event'),child('UIResult'),child('UIRequest')
 if event~=self._eventRemote then
  if self._eventConnection then self._eventConnection:Disconnect();self._eventConnection=nil end
  self._eventRemote=event
  if event and event.OnClientEvent then self._eventConnection=event.OnClientEvent:Connect(function(kind,payload) self:_receive(kind,payload) end) end
 end
 if result~=self._resultRemote then
  if self._resultConnection then self._resultConnection:Disconnect();self._resultConnection=nil end
  self._resultRemote=result
  if result and result.OnClientEvent then self._resultConnection=result.OnClientEvent:Connect(function(payload) self:_result(payload) end) end
 end
 self._requestRemote=request
 if self:_available() then
  if self.profile then self.status='ready' end
  if self._hasSubscribed and not self._started then
   self._started=true;self:request('State')
  end
 elseif self._hasSubscribed then
  self.status='error'
  self:_emit('toast','Mountain UI service unavailable. Waiting for the server connection.')
 end
end
function Store:subscribe(fn)
 assert(type(fn)=='function','subscribe expects a function')
 if self._destroyed then return function() end end
 local token={};self._listeners[token]=fn
 self._hasSubscribed=true
 self:_discover()
 local connected=true
 return function()
  if connected then connected=false;self._listeners[token]=nil end
 end
end
function Store:_timeout(record,message)
 if self._destroyed or self._requests[record.id]~=record then return end
 record.timer=nil;record.status='timeout'
 local visible=self.pending[record.id]
 visible.status='timeout';visible.message=message or 'No confirmation yet. Retry checks the same request; it does not start a new action.'
 if record.action=='State' and not self.profile then self.status='error' end
 self:_emit('pending',visible)
 self:_emit('timeout',visible)
end
function Store:_send(record)
 self:_cancel(record)
 record.status='pending';record.attempts+=1;record.sentAt=self._runtime.monotonic()
 local visible={id=record.id,action=record.action,payload=copy(record.payload),status='pending',sentAt=record.sentAt,attempts=record.attempts}
 self.pending[record.id]=visible
 if record.action=='State' and not self.profile then self.status='loading' end
 record.timer=self._runtime.delay(8,function() self:_timeout(record) end)
 self:_emit('pending',visible)
 if self._destroyed then return end
 local ok=pcall(function() self._requestRemote:FireServer(record.id,record.action,copy(record.payload)) end)
 if not ok and self._requests[record.id]==record then
  self:_cancel(record)
  self:_timeout(record,'Connection unavailable. The outcome is unknown; retry this same request when connected.')
 end
end
function Store:request(action,payload,callback)
 if self._destroyed or not actions[action] then return nil end
 if self._byAction[action] then return nil end
 if not self:_available() then
  self.status='error';self:_emit('toast','Mountain UI service unavailable. No action was confirmed.');return nil
 end
 self._sequence+=1
 local id=self._token..':'..tostring(self._sequence)
 local record={id=id,action=action,payload=copy(payload),callback=if type(callback)=='function' then callback else nil,attempts=0}
 self._requests[id]=record;self._byAction[action]=id
 self:_send(record)
 return id
end
function Store:retry(id)
 if self._destroyed or not self:_available() then return false end
 local record=self._requests[id]
 if not record or record.status~='timeout' then return false end
 self:_send(record);return true
end
function Store:now()
 return math.floor(self._runtime.monotonic()+self._epochOffset)
end
function Store:clock()
 local ok,now=pcall(self._runtime.clock)
 if ok and finite(now) then return now end
 return self._runtime.monotonic()+self._clockOffset
end
function Store:destroy()
 if self._destroyed then return end
 self._destroyed=true
 for _,record in pairs(self._requests) do self:_cancel(record) end
 for _,name in ipairs({'_eventConnection','_resultConnection','_addedConnection','_removedConnection'}) do
  if self[name] then self[name]:Disconnect();self[name]=nil end
 end
 table.clear(self._listeners);table.clear(self._requests);table.clear(self._byAction)
 table.clear(self._history);table.clear(self._completed);table.clear(self.pending)
 self._requestRemote=nil;self._resultRemote=nil;self._eventRemote=nil;self._remotes=nil
end
-- The optional runtime provides scheduler/time/network-ID dependencies for
-- deterministic off-engine verification; normal clients pass only remotes.
function ClientState.new(remotes,runtime)
 runtime=runtime or defaultRuntime()
 local self=setmetatable({profile=nil,battle=false,status='loading',pending={},lastResult=nil,
  _runtime=runtime,_remotes=remotes,_listeners={},_requests={},_byAction={},_history={},_completed={},
  _sequence=0,_token=runtime.token(),_epochOffset=runtime.epoch()-runtime.monotonic(),_clockOffset=0},Store)
 self:_discover()
 if remotes and remotes.ChildAdded then self._addedConnection=remotes.ChildAdded:Connect(function() self:_discover() end) end
 if remotes and remotes.ChildRemoved then self._removedConnection=remotes.ChildRemoved:Connect(function() self:_discover() end) end
 return self
end
return ClientState
