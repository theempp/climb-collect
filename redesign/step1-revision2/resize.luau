-- Owner selected 180x220 plots and 60 studs of front walking space, 2026-10-24.
-- Run once on the Step1 review, then Save As revision2. Original files preserved.
local w=workspace.MountainEmpire_Step1
assert(not w:GetAttribute('Revision2'), 'Already resized')
for _,plot in w.SanctuaryPlots:GetChildren() do
 local i=tonumber(plot.Name:match('%d+'))
 local x=(i-4.5)*188
 local floor=plot.Plot_110x120
 local oldX=floor.Position.X
 for _,p in plot:GetChildren() do
  if p:IsA('BasePart') then
   local pos=p.Position
   if p==floor then p.Size=Vector3.new(180,2,220);p.Position=Vector3.new(x,-1,110);p.Name='Plot_180x220'
   elseif p.Name=='PlotEdge' then p.Size=Vector3.new(.5,.1,220);p.Position=Vector3.new(x+(pos.X<oldX and -89.75 or 89.75),.05,110)
   elseif p.Name=='FrontEdge' or p.Name=='RearEdge' then p.Size=Vector3.new(180,.1,.5);p.Position=Vector3.new(x,.05,p.Name=='FrontEdge' and .25 or 219.75)
   else p.Position=Vector3.new(pos.X-oldX+x,pos.Y,pos.Z+100) end
  end
 end
end
for _,p in w:GetChildren() do
 if p.Name:match('^Buffer_') then local i=tonumber(p.Name:match('%d+'));p.Size=Vector3.new(8,2,220);p.Position=Vector3.new((i-4)*188,-1,110) end
end
local a=w.EssentialAccess
for _,p in a:GetChildren() do
 if p.Name=='AccessGround' then p.Size=Vector3.new(1516,4,120);p.Position=Vector3.new(0,-2,-60)
 else p:Destroy() end
end
local band=Instance.new('Part');band.Name='FrontWalkingArea_1496x60';band.Size=Vector3.new(1496,.16,60);band.Position=Vector3.new(0,.08,-30);band.Anchored=true;band.Material=Enum.Material.SmoothPlastic;band.Color=Color3.fromRGB(184,184,169);band.TopSurface=Enum.SurfaceType.Smooth;band.BottomSurface=Enum.SurfaceType.Smooth;band.Parent=a
for _,folder in {w.GatewayTerrace,w.ThreeGates_NoGameplay} do
 for _,p in folder:GetDescendants() do if p:IsA('BasePart') then p.Position-=Vector3.new(0,0,42) end end
end
for _,p in w.TerrainMassing_NoLandscaping:GetChildren() do
 local pos=p.Position;local size=p.Size
 if p.Name=='BasinSideLower' or p.Name=='BasinSideUpper' then
  p.Position=Vector3.new(pos.X+(pos.X<0 and -280 or 280),pos.Y,pos.Z+29);p.Size=Vector3.new(size.X,size.Y,size.Z+142)
 elseif p.Name=='RearTerraceLower' or p.Name=='RearTerraceUpper' then
  p.Position+=Vector3.new(0,0,100);p.Size=Vector3.new(size.X+560,size.Y,size.Z)
 elseif p.Name=='BasinFoundation' then p.Size=Vector3.new(1780,8,962);p.Position+=Vector3.new(0,0,29)
 elseif p.Name=='GateFlankTerrace' or p.Name=='GateFlankUpper' then
  p.Size=Vector3.new(size.X+280,size.Y,size.Z);p.Position=Vector3.new(pos.X+(pos.X<0 and -140 or 140),pos.Y,pos.Z-42)
 elseif p.Name=='MountainPeakMassing' then
  p.Position=Vector3.new(pos.X*1.45,pos.Y,pos.Z-42);p.Size=Vector3.new(size.X,size.Y,size.Z*1.45)
 else p.Position-=Vector3.new(0,0,42) end
end
w:SetAttribute('Revision2',true)
w:SetAttribute('PlotWidth',180);w:SetAttribute('PlotDepth',220);w:SetAttribute('FrontWalkingDepth',60)
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(0,900,850),Vector3.new(0,0,-10))
game:GetService('ChangeHistoryService'):SetWaypoint('Larger plots and60-stud front walking space')
return 'Revision2: eight180x220 plots;1496 frontage;60-stud walking area'
