-- polish_p0.client.luau : HUD polish P0. Where every "SAFE RETURN" label projects on screen, then drop local Health so the native bar shows.
local cam=workspace.CurrentCamera;local out={labels={},vp={cam.ViewportSize.X,cam.ViewportSize.Y}}
for _,d in ipairs(workspace:GetDescendants()) do
	if d:IsA('TextLabel') and d.Text:upper():find('SAFE RETURN') then
		local g=d:FindFirstAncestorWhichIsA('BillboardGui');local a=g and (g.Adornee or g.Parent)
		local pos=a and a:IsA('BasePart') and a.Position or a and a:IsA('Attachment') and a.WorldPosition
		local sp,on=pos and cam:WorldToViewportPoint(pos)
		table.insert(out.labels,{path=d:GetFullName(),screen=sp and {math.floor(sp.X),math.floor(sp.Y),math.floor(sp.Z)},onScreen=on,maxDist=g and g.MaxDistance})
	end
end
local h=game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
out.health=h and {h.Health,h.MaxHealth}
out.coreHealth=game:GetService('StarterGui'):GetCoreGuiEnabled(Enum.CoreGuiType.Health)
if h then h.Health=h.MaxHealth*.5 end
task.wait(1)
return game:GetService('HttpService'):JSONEncode(out)
