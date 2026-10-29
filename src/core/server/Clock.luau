-- Clock (ServerScriptService.CC_CoreServer): the only source of wall time for persistence and timers.
-- os.time() (UTC seconds) in play; tests move `offset` to simulate offline gaps (A1 acceptance).
local Clock = { offset = 0 }

function Clock.now()
	return os.time() + Clock.offset
end

return Clock
