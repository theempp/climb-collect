-- Command-bar job (Edit mode): reports MeshParts that appear more than once under SS_Mountain; dedupe=true removes extras.
return function()
	local dedupe = true
	local seen, dups, removed, sameMesh = {}, {}, 0, 0
	for _, p in workspace.SS_Mountain:GetDescendants() do
		if p:IsA("MeshPart") then
			local first = seen[p.Name]
			if not first then
				seen[p.Name] = p
			else
				table.insert(dups, p.Name)
				if first.MeshId ~= p.MeshId and first.Size == p.Size and first.Position == p.Position then
					sameMesh += 1 -- different upload of identical geometry
				end
				if dedupe and first.Size == p.Size and (first.Position - p.Position).Magnitude < 0.01 then
					p:Destroy()
					removed += 1
				end
			end
		end
	end
	local n = 0
	for _ in seen do
		n += 1
	end
	return string.format("DEDUPE unique=%d dups=%d removed=%d sameGeomDiffUpload=%d %s", n, #dups, removed, sameMesh, table.concat(dups, ",", 1, math.min(#dups, 6)))
end
