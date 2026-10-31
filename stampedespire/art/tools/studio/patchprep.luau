-- Command-bar job (Edit mode): before importing ss_patch.fbx, removes the old MeshParts it replaces.
-- PREFIX "Z" = every zone mesh (milestone 5 bend re-import); the backdrop stays (postimport moves it).
return function()
	local PREFIX = "Z"
	local removed = 0
	for _, p in workspace.SS_Mountain:GetDescendants() do
		if p:IsA("MeshPart") and p.Name:sub(1, #PREFIX) == PREFIX then
			p:Destroy()
			removed += 1
		end
	end
	return string.format("PATCHPREP prefix=%s removed=%d", PREFIX, removed)
end
