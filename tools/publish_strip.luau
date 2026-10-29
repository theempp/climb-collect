-- Publish strip (dev tool, Edit mode). Run ONLY in a publish copy of the place (File > Save to File As
-- ClimbAndCollect.Publish.rbxl first), never in the working place: it deletes the Studio-only dev tools.
-- Paste into execute_luau (Edit) after setting _G.CC_PUBLISH_COPY = game.Name (the open file must be the copy).
-- Keeps gameplay intact; the Studio-only DevRequest/DevBridge are created at runtime only when RunService:IsStudio(),
-- and CC_CoreService also destroys these folders at startup in a live server (backstop).
assert(_G.CC_PUBLISH_COPY == game.Name and string.find(game.Name, "Publish", 1, true), "open the Publish copy and set _G.CC_PUBLISH_COPY = game.Name")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local removed = {}
for _, pair in ipairs({
	{ RS, "CC_DevTools" }, -- TutorialBot, BChecks
	{ SS, "CC_DevTools" }, -- Sync
	{ SS, "CC_DevBridge" },
	{ SS, "CC_Checkpoints" }, -- dev snapshots (whole-map terrain copies)
	{ SS, "CC_Generators" }, -- world generators (the built world is already in Workspace)
	{ SS, "CC_Prototypes" },
}) do
	local inst = pair[1]:FindFirstChild(pair[2])
	if inst then
		removed[#removed + 1] = inst:GetFullName() .. " (" .. #inst:GetDescendants() .. ")"
		inst:Destroy()
	end
end
local tests = SSS:FindFirstChild("CC_CoreServer") and SSS.CC_CoreServer:FindFirstChild("Tests")
if tests then
	removed[#removed + 1] = tests:GetFullName()
	tests:Destroy()
end
return "removed: " .. table.concat(removed, ", ")
