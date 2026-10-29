-- Weather (ServerScriptService.CC_CoreServer), v4 P4 run 2: the server's weather schedule (concept LOCKED #13:
-- dynamic day/night + weather with mobile quality tiers, only after a measured cost test; numbers PROPOSED,
-- CoreConfig WEATHER). The server owns the state; CC_WeatherClient draws it (lighting, particles by quality tier).
-- * Day/night: deterministic from server time (workspace attribute CC_DayStart): every client computes the same
--   ClockTime, nothing streams per frame. Day 5:30 -> 19:30 takes most of the cycle, the night the rest.
-- * Weather: clear / mist / snow / gust, each held minHold..maxHold s; workspace attributes CC_Weather + CC_WeatherAt.
--   Weather.current() is the hook for weather-linked mutations (master.md §0.7) when that system lands.
-- * CC_WeatherOff (workspace attribute, Studio dev action "weather") freezes it for perf comparisons.
local Weather = {}
local ctx, C
local rng = Random.new()

function Weather.current()
	return workspace:GetAttribute("CC_Weather") or "clear"
end

local function set(state)
	workspace:SetAttribute("CC_Weather", state)
	workspace:SetAttribute("CC_WeatherAt", workspace:GetServerTimeNow())
end

function Weather.init(c)
	ctx = c
	C = c.C
	local W = C.WEATHER
	-- the day starts mid-morning at server start (first players see daylight)
	workspace:SetAttribute("CC_DayStart", workspace:GetServerTimeNow() - W.dayMinutes * 60 * 0.25)
	set("clear")
	task.spawn(function()
		while true do
			task.wait(rng:NextNumber(W.minHold, W.maxHold))
			if not workspace:GetAttribute("CC_WeatherOff") then
				-- clear half the time, the rest split between the others; never the same twice in a row
				local cur = Weather.current()
				local pick
				repeat
					local r = rng:NextNumber()
					pick = (r < 0.45) and "clear" or W.states[rng:NextInteger(2, #W.states)]
				until pick ~= cur
				set(pick)
			end
		end
	end)
	if ctx.devHandlers then
		-- Studio only: { state = "snow", clock = 22, off = true/false }
		ctx.devHandlers.weather = function(_, p)
			if type(p.state) == "string" and table.find(W.states, p.state) then
				set(p.state)
			end
			if type(p.clock) == "number" then
				-- shift the day start so ClockTime reads p.clock now
				local cyc = W.dayMinutes * 60
				local dayShare = W.dayShare
				local h = p.clock
				local phase
				if h >= W.nightTo and h < W.nightFrom then
					phase = (h - W.nightTo) / (W.nightFrom - W.nightTo) * dayShare
				else
					local hn = (h - W.nightFrom) % 24
					phase = dayShare + hn / (24 - (W.nightFrom - W.nightTo)) * (1 - dayShare)
				end
				workspace:SetAttribute("CC_DayStart", workspace:GetServerTimeNow() - phase * cyc)
			end
			if p.off ~= nil then
				workspace:SetAttribute("CC_WeatherOff", p.off == true)
			end
		end
	end
end

return Weather
