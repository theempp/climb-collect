-- Command-bar job (Edit mode): integrity snapshot (mesh count, top-level Workspace children, HttpEnabled).
return function()
	local n, tris = 0, 0
	for _, p in workspace.SS_Mountain:GetDescendants() do
		if p:IsA("MeshPart") then
			n += 1
		end
	end
	local kids = {}
	for _, c in workspace:GetChildren() do
		table.insert(kids, c.Name)
	end
	table.sort(kids)
	return string.format("CHECK meshparts=%d workspace=[%s]", n, table.concat(kids, ","))
end
