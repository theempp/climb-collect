-- Command-bar job (Edit mode): lists every SS_Mountain MeshPart's mesh and texture asset ids (upload report).
return function()
	local rows = {}
	for _, p in workspace.SS_Mountain:GetDescendants() do
		if p:IsA("MeshPart") then
			table.insert(rows, string.format("%s\t%s\t%s", p.Name, p.MeshId, p.TextureID))
		end
	end
	table.sort(rows)
	return "ASSETIDS " .. #rows .. "\n" .. table.concat(rows, "\n")
end
