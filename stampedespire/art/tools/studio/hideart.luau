-- Command-bar job (Edit mode), Sections copy only (P1 pace test): parks the old 4-zone Blender mountain in
-- ServerStorage so only the greybox track shows. Refuses to run in any other place file.
return function()
	if not string.find(game.Name, "Sections", 1, true) then
		return "HIDEART refused: place is " .. game.Name
	end
	local SS = game:GetService("ServerStorage")
	local m = workspace:FindFirstChild("SS_Mountain")
	local parked = SS:FindFirstChild("SS_Mountain_Parked")
	if not m then
		return "HIDEART no SS_Mountain in Workspace (parked: " .. tostring(parked ~= nil) .. ")"
	end
	if parked then
		return "HIDEART refused: ServerStorage already has SS_Mountain_Parked"
	end
	m.Name = "SS_Mountain_Parked"
	m.Parent = SS
	return "HIDEART parked SS_Mountain (" .. #m:GetDescendants() .. " descendants)"
end
