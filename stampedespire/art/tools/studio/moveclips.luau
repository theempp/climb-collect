-- Command-bar job (Edit mode): moves ReplicatedStorage.SS_Creatures.Clips (raw KeyframeSequences, ~18,000 instances
-- replicated to every client) to ServerStorage.SS_CreatureClips. Safe to re-run.
return function()
	local RepS = game:GetService("ReplicatedStorage")
	local SS = game:GetService("ServerStorage")
	local root = RepS:FindFirstChild("SS_Creatures")
	local clips = root and root:FindFirstChild("Clips")
	local before = #RepS:GetDescendants()
	if clips then
		local dest = SS:FindFirstChild("SS_CreatureClips")
		if dest then
			dest:Destroy()
		end
		clips.Name = "SS_CreatureClips"
		clips.Parent = SS
	end
	return string.format("MOVECLIPS moved=%s ReplicatedStorage %d -> %d, ServerStorage %d", tostring(clips ~= nil), before,
		#RepS:GetDescendants(), #SS:GetDescendants())
end
