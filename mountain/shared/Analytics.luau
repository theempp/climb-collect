-- Analytics: the one wrapper around AnalyticsService (design/funnels-analytics-spec-2026-10-28.md in climb&collect).
-- Pure core: the service, clock and CCU come in through A.new(deps), so it runs in plain Luau tests.
-- Rules: event names and field values come only from the enums below (never player text); every call is
-- pcall'd and rate-limited under 120 + 20 x CCU per minute; gameplay never waits on it.
local A={}

A.EVENTS={}
for _,n in {'session_start','session_end','area_enter','loading_time',
 'egg_grabbed','egg_banked','egg_lost','fall','hatch','rank_up','tier_up','guardian_result',
 'daily_claim','quest_complete','streak_broken','streak_saved','banner_seen',
 'shop_open','shop_view','purchase_attempt','purchase_granted','purchase_failed','ladder_step',
 'problem_report','settings_changed','error_count','save_fail','save_retry',
 'perf_sample','alert','flag_changed'} do A.EVENTS[n]=true end

-- F1 area, F2 device, F3 context. Values outside these sets are logged as 'other'.
A.FIELDS={
 area={sanctuary=true,lake=true,blossom=true,azure=true,sunstone=true,violet=true,inferno=true,astral=true,summit=true,menu=true},
 device={phone=true,tablet=true,desktop=true,console=true},
 context={},
}
for _,n in {'quit','idle','fall','died','disconnect','theft','guardian','win','loss','flee',
 'common','uncommon','rare','epic','legendary','mythic','coin','hatch','cosmetic','egg','boost',
 'kingdom','purchase','graphics','other','audio','haptics','reduce_effects','shop','save','error'} do A.FIELDS.context[n]=true end
for i=1,10 do A.FIELDS.context['coin_'..i]=true;A.FIELDS.context['hatch_'..i]=true end

A.FUNNELS={onboarding=true,egg_run=true,guardian=true,home_base=true,shop=true,ladder=true,daily=true,hatch=true,week_one=true}
A.CURRENCIES={Coins=true}
A.TRANSACTIONS={quest=true,daily=true,bank=true,hatch=true,summit=true,ladder_income=true,
 tier_up=true,habitat=true,decor=true,egg_ticket=true,hatch_skip=true,cosmetic=true}

local function clean(f)
 if f==nil then return nil end
 local out={}
 for k,set in A.FIELDS do
  local v=f[k]
  if v~=nil then out[k]=set[v] and v or 'other' end
 end
 return out
end
A.clean=clean

-- Budget per minute; `share` keeps us below the platform ceiling (other callers, bursts).
function A.budget(ccu,share) return math.floor((120+20*math.max(ccu,0))*(share or .8)) end

function A.new(deps)
 local self={svc=deps.service,now=deps.now or os.clock,ccu=deps.ccu or function() return 1 end,
  build=deps.build or 'dev',share=deps.share,warn=deps.warn or function() end,
  windowStart=-math.huge,used=0,dropped=0,failed=0,counts={}}

 local function allow()
  local t=self.now()
  if t-self.windowStart>=60 then self.windowStart=t;self.used=0 end
  if self.used>=A.budget(self.ccu(),self.share) then self.dropped+=1;return false end
  self.used+=1;return true
 end
 local function call(method,...)
  if not self.svc or not allow() then return false end
  local ok,err=pcall(self.svc[method],self.svc,...)
  if not ok then self.failed+=1;self.warn('Analytics '..method..': '..tostring(err)) end
  return ok
 end

 function self.custom(player,name,value,fields)
  if not A.EVENTS[name] then self.warn('Analytics unknown event '..tostring(name));return false end
  return call('LogCustomEvent',player,name,value or 1,clean(fields))
 end
 function self.onboarding(player,step,stepName,fields)
  return call('LogOnboardingFunnelStepEvent',player,step,stepName,clean(fields))
 end
 function self.funnel(player,funnel,sessionId,step,stepName,fields)
  if not A.FUNNELS[funnel] then self.warn('Analytics unknown funnel '..tostring(funnel));return false end
  return call('LogFunnelStepEvent',player,funnel,sessionId,step,stepName,clean(fields))
 end
 function self.progression(player,kind,path,level,levelName,fields)
  local m=({start='LogProgressionStartEvent',complete='LogProgressionCompleteEvent',fail='LogProgressionFailEvent'})[kind]
  if not m then return false end
  return call(m,player,path,level,levelName,clean(fields))
 end
 -- flowType is the Enum.AnalyticsEconomyFlowType item, passed by the caller (keeps this file Enum-free).
 function self.economy(player,flowType,currency,amount,ending,transaction,sku,fields)
  if not A.CURRENCIES[currency] or not A.TRANSACTIONS[transaction] then
   self.warn('Analytics unknown currency/transaction '..tostring(currency)..'/'..tostring(transaction));return false end
  return call('LogEconomyEvent',player,flowType,currency,amount,ending,transaction,sku or '',clean(fields))
 end

 -- Counters (errors, coins per source) are summed locally and sent once per flush.
 function self.count(name,n,fields)
  if not A.EVENTS[name] then return end
  local key=name..'|'..(fields and fields.area or '')..'|'..(fields and fields.device or '')..'|'..(fields and fields.context or '')
  local c=self.counts[key]
  if c then c.n+=n or 1 else self.counts[key]={name=name,n=n or 1,fields=fields} end
 end
 function self.flush(player)
  local sent=0
  for k,c in self.counts do
   if self.custom(player,c.name,c.n,c.fields) then sent+=1 end
   self.counts[k]=nil
  end
  return sent
 end
 return self
end

return A
