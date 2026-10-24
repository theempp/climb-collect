-- Store (ServerScriptService.CC_CoreServer): persistence adapter. Profile code only sees this interface:
--   store:read(key)        -> ok, value|nil, err
--   store:update(key, fn)  -> ok, value|nil, err   fn(old) returns the new value, or nil to cancel the write
--                            (UpdateAsync semantics: fn may run more than once; keep it free of side effects
--                            other than setting locals the caller resets before each call).
-- Two implementations:
--   Store.datastore(name)  real DataStoreService (UNVERIFIED: the place is unpublished, PlaceId = 0)
--   Store.memory(opts)     in-memory mock for Studio + tests. Values round-trip through JSON like a DataStore,
--                          so non-serializable data fails here too. Failure injection: failNext (n calls),
--                          failAll (bool), latency (s), conflicts (n: run fn twice to mimic a retried write).
local HttpService = game:GetService("HttpService")

local Store = {}

---------------------------------------------------------------- memory mock
local Memory = {}
Memory.__index = Memory

function Store.memory(opts)
	opts = opts or {}
	return setmetatable({
		kind = "memory",
		backend = opts.backend or {}, -- share one backend between two "servers" in tests
		failNext = 0,
		failAll = false,
		latency = opts.latency or 0,
		conflicts = 0,
		failAfterCommit = 0, -- response lost AFTER durable write; exercises uncertain outcome replay
		calls = { read = 0, update = 0, failed = 0 },
	}, Memory)
end

function Memory:_gate(kind)
	self.calls[kind] += 1
	if self.latency > 0 then
		task.wait(self.latency)
	end
	if self.failAll then
		self.calls.failed += 1
		return false, "mock: store unavailable (failAll)"
	end
	if self.failNext > 0 then
		self.failNext -= 1
		self.calls.failed += 1
		return false, "mock: store request failed (failNext)"
	end
	return true
end

function Memory:read(key)
	local ok, err = self:_gate("read")
	if not ok then
		return false, nil, err
	end
	local raw = self.backend[key]
	return true, raw and HttpService:JSONDecode(raw) or nil, nil
end

function Memory:update(key, fn)
	local ok, err = self:_gate("update")
	if not ok then
		return false, nil, err
	end
	local runs = 1 + math.max(0, self.conflicts)
	self.conflicts = 0
	local new
	for _ = 1, runs do
		local raw = self.backend[key]
		local old = raw and HttpService:JSONDecode(raw) or nil
		local okFn, res = pcall(fn, old)
		if not okFn then
			return false, nil, "transform error: " .. tostring(res)
		end
		new = res
	end
	if new == nil then
		local raw = self.backend[key]
		return true, raw and HttpService:JSONDecode(raw) or nil, "cancelled"
	end
	local okEnc, enc = pcall(HttpService.JSONEncode, HttpService, new)
	if not okEnc then
		return false, nil, "serialize: " .. tostring(enc)
	end
	self.backend[key] = enc
	if self.failAfterCommit > 0 then
		self.failAfterCommit -= 1
		return false, nil, "mock: response lost after commit"
	end
	return true, HttpService:JSONDecode(enc), nil
end

---------------------------------------------------------------- real DataStore (UNVERIFIED in Studio)
local DS = {}
DS.__index = DS

function Store.datastore(name)
	local DataStoreService = game:GetService("DataStoreService")
	local ok, ds = pcall(DataStoreService.GetDataStore, DataStoreService, name)
	return setmetatable({ kind = "datastore", ds = ok and ds or nil, initErr = (not ok) and tostring(ds) or nil, service = DataStoreService }, DS)
end

function DS:_budget(reqType)
	-- wait (bounded) for request budget instead of letting the request throttle
	for _ = 1, 20 do
		local okB, b = pcall(self.service.GetRequestBudgetForRequestType, self.service, reqType)
		if not okB or b > 0 then
			return
		end
		task.wait(0.5)
	end
end

function DS:read(key)
	if not self.ds then
		return false, nil, self.initErr
	end
	self:_budget(Enum.DataStoreRequestType.GetAsync)
	local ok, res = pcall(self.ds.GetAsync, self.ds, key)
	if not ok then
		return false, nil, tostring(res)
	end
	return true, res, nil
end

function DS:update(key, fn)
	if not self.ds then
		return false, nil, self.initErr
	end
	self:_budget(Enum.DataStoreRequestType.UpdateAsync)
	local cancelled = false
	local ok, res = pcall(self.ds.UpdateAsync, self.ds, key, function(old)
		local new = fn(old)
		cancelled = new == nil
		return new
	end)
	if not ok then
		return false, nil, tostring(res)
	end
	return true, res, cancelled and "cancelled" or nil
end

---------------------------------------------------------------- choice
-- Real DataStore only in a published place; Studio with PlaceId 0 cannot reach DataStores at all.
function Store.default(name)
	if game.PlaceId ~= 0 then
		return Store.datastore(name)
	end
	return Store.memory()
end

return Store
