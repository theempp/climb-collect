-- Original cosmetic study only. No catalogue entry, platform ID, checkout or grant.
return function()
 local parent=workspace.World.Fairground
 if parent:FindFirstChild('StarterSetPreview') then return end
 local m=Instance.new('Model');m.Name='StarterSetPreview';m:SetAttribute('PreviewOnly',true);m.Parent=parent
 local Art=require(game.ReplicatedStorage.CC_Core.CommerceArt)
 local at=CFrame.new(73,50,2022)
 for i,id in {'flag','lantern'} do local item=Art.make(id,m,at*CFrame.new((i-1)*5,0,0),1.4);for _,p in item:GetDescendants() do if p:IsA('BasePart') then p.Color=Color3.fromRGB(22,174,173) end end end
 local p=Instance.new('Part');p.Name='TagFramePreview';p.Anchored=true;p.CanCollide=false;p.Size=Vector3.new(12,6,1);p.CFrame=at*CFrame.new(4,11,0);p.Color=Color3.fromRGB(255,207,73);p.Parent=m
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Back;gui.Parent=p
 local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text='EXPEDITION STARTER\nPennant • lantern • tag frame\nPREVIEW ONLY';t.TextScaled=true;t.Font=Enum.Font.FredokaOne;t.TextColor3=Color3.fromRGB(29,46,64);t.Parent=gui
end
