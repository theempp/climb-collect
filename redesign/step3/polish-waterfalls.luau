local env=workspace.MountainEmpire_Step1.AlpineEnvironment_Step3
assert(not env:GetAttribute('WaterfallsRefined'))
for _,name in {'WestGateLandscape','EastGateLandscape'} do
 local m=env[name] local x=name=='WestGateLandscape' and -222 or 222
 for _,p in m:GetChildren() do if p.Name=='CascadeRibbon' or p.Name=='CascadeWhitewater' then p:Destroy() end end
 local function water(n,y,z,sx,sy,sz,color)
  local p=Instance.new('Part') p.Name=n p.Size=Vector3.new(sx,sy,sz) p.Position=Vector3.new(x,y,z) p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Color=color or Color3.fromRGB(119,204,214) p.Material=Enum.Material.SmoothPlastic p.Transparency=.12 p.Parent=m return p
 end
 water('SpringPool',63.2,-184,15,.45,42)
 water('UpperCascade',46,-164,10,34,1)
 water('TerraceRill',29.2,-134,10,.45,60)
 water('LowerCascade',14.5,-104,10,29,1)
 for _,v in {{29.6,-163},{.65,-103}} do water('Whitewater',v[1],v[2],12,.55,3,Color3.fromRGB(226,241,239)) end
 for _,dx in {-3,0,3} do
  local p=water('WaterStreak',14.5,-103.4,.35,27,.12,Color3.fromRGB(205,234,235)) p.Position+=Vector3.new(dx,0,0)
 end
end
env:SetAttribute('WaterfallsRefined',true)
return 'Visible stepped cascades connected to their pools'
