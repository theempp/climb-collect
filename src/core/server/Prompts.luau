-- Prompts (ServerScriptService.CC_CoreServer): server-created ProximityPrompts with hold validation.
-- A prompt's Triggered is accepted only if the server saw PromptButtonHoldBegan from the same player, the hold
-- lasted at least HoldDuration (minus a small network tolerance), the character is within range, alive, and was
-- not hit (staggered) after the hold began. Mobile: tap-and-hold works on the same prompt, no aiming needed.
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("CC_Core"):WaitForChild("CoreConfig"))

local Prompts = {}
local holds = setmetatable({}, { __mode = "k" }) -- [prompt] = { [player] = os.clock() at hold start }
local lastHit = {} -- [player] = os.clock() of the last guardian hit

function Prompts.noteHit(plr)
	lastHit[plr] = os.clock()
end
function Prompts.forget(plr)
	lastHit[plr] = nil
end

function Prompts.make(parent, props)
	local p = Instance.new("ProximityPrompt")
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.GamepadKeyCode = Enum.KeyCode.ButtonX
	p.MaxActivationDistance = C.CLAIM_RANGE
	for k, v in pairs(props) do
		p[k] = v
	end
	holds[p] = {}
	p.PromptButtonHoldBegan:Connect(function(plr)
		holds[p][plr] = os.clock()
	end)
	p.PromptButtonHoldEnded:Connect(function(plr)
		-- keep the start time briefly: Triggered can arrive just after HoldEnded
		local t0 = holds[p][plr]
		task.delay(0.5, function()
			if holds[p] and holds[p][plr] == t0 then
				holds[p][plr] = nil
			end
		end)
	end)
	p.Parent = parent
	return p
end

-- validate(prompt, plr) -> ok, reason
function Prompts.validate(prompt, plr)
	local ch = plr.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return false, "nochar"
	end
	local anchorPart = prompt.Parent
	local pos = anchorPart and (anchorPart:IsA("BasePart") and anchorPart.Position or anchorPart:IsA("Attachment") and anchorPart.WorldPosition)
	if not pos or (hrp.Position - pos).Magnitude > prompt.MaxActivationDistance + 4 then
		return false, "range"
	end
	local t0 = holds[prompt] and holds[prompt][plr]
	if prompt.HoldDuration > 0 then
		if not t0 or os.clock() - t0 < prompt.HoldDuration - C.HOLD_TOLERANCE then
			return false, "hold"
		end
	end
	if t0 and lastHit[plr] and lastHit[plr] >= t0 then
		return false, "hit"
	end
	if holds[prompt] then
		holds[prompt][plr] = nil
	end
	return true
end

return Prompts
