-- Net (ReplicatedStorage.CC_Core): RemoteEvents under ReplicatedStorage.CC_Remotes (the folder CC_CheckpointService
-- already uses). The server creates them; clients wait. Core remotes:
--   CoreState   S->C  full state snapshot (backpack, progress, timers, save state)
--   CoreToast   S->C  one-line message { text, kind }
--   CoreFx      S->C  effects { kind = "stagger" | "claim" | "net" | "bank" | ... }
--   CoreRequest C->S  (action, payload) rate-limited and validated on the server
--   DevRequest  C->S  Studio-only test hooks (created only when RunService:IsStudio())
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")

local Net = {}
local NAMES = { "CoreState", "CoreToast", "CoreFx", "CoreRequest" }

local function folder()
	local f = RS:FindFirstChild("CC_Remotes")
	if not f and Run:IsServer() then
		f = Instance.new("Folder")
		f.Name = "CC_Remotes"
		f.Parent = RS
	end
	return f or RS:WaitForChild("CC_Remotes")
end

function Net.serverInit()
	local f = folder()
	for _, n in ipairs(NAMES) do
		if not f:FindFirstChild(n) then
			local e = Instance.new("RemoteEvent")
			e.Name = n
			e.Parent = f
		end
	end
	if Run:IsStudio() and not f:FindFirstChild("DevRequest") then
		local e = Instance.new("RemoteEvent")
		e.Name = "DevRequest"
		e.Parent = f
	end
	return f
end

function Net.get(name)
	return folder():WaitForChild(name, 30)
end

return Net
