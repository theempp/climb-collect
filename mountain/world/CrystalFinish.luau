-- Replace decorative rectangular mineral placeholders with closed pointed prisms.
local F={}
local function triangle(parent,a,b,c,color)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=back:Cross(right);local h=math.abs(ab:Dot(up))
 for _,v in ipairs({{(a+b)/2,right,up,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,up,-back,math.abs(ac:Dot(back))}}) do
  local p=Instance.new('WedgePart');p.Name='MineralFace';p.Size=Vector3.new(.035,h,v[5]);p.CFrame=CFrame.fromMatrix(v[1],v[2],v[3],v[4]);p.Color=color;p.Material=Enum.Material.Slate;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=parent
 end
end
function F.apply(world)
 assert(game.PlaceId==0 and not game:GetService('RunService'):IsRunning(),'Local Edit only')
 assert(not world:GetAttribute('CrystalFinishRevision'),'Already applied')
 local archive=Instance.new('Folder');archive.Name='CrystalRectanglesPrior';archive.Parent=game.ServerStorage
 local parts={};for _,p in ipairs(world.EnvironmentComposition:GetDescendants()) do if p:IsA('BasePart') and p.Name=='Facet' and p.Parent.Name=='MineralCluster' and not p.CanCollide then table.insert(parts,p) end end
 for index,p in ipairs(parts) do
  local cf,size,color=p.CFrame,p.Size,p.Color:Lerp(Color3.fromRGB(165,171,191),.25)
  local model=Instance.new('Model');model.Name='PointedCrystal';model:SetAttribute('SourceCFrame',cf);model:SetAttribute('SourceSize',size)
  local low,high={},{}
  for i=1,5 do local a=(i-1)*math.pi*2/5
   low[i]=cf:PointToWorldSpace(Vector3.new(math.cos(a)*size.X*.5,-size.Y*.5,math.sin(a)*size.Z*.5))
   high[i]=cf:PointToWorldSpace(Vector3.new(math.cos(a)*size.X*.5,size.Y*(.24+.04*math.sin(i)),math.sin(a)*size.Z*.5))
  end
  local tip=cf:PointToWorldSpace(Vector3.new(size.X*.12,size.Y*.5,size.Z*-.08))
  local base=cf:PointToWorldSpace(Vector3.new(0,-size.Y*.5,0))
  for i=1,5 do local n=i%5+1;local tint=color:Lerp(Color3.fromRGB(235,237,245),.04*(i%3))
   triangle(model,low[i],low[n],high[i],tint);triangle(model,low[n],high[n],high[i],tint);triangle(model,high[i],high[n],tip,tint);triangle(model,low[n],low[i],base,tint)
  end
  model.Parent=p.Parent;p.Parent=archive
  if index%12==0 then task.wait() end
 end
 world:SetAttribute('CrystalFinishRevision',1);return {crystals=#parts}
end
return F
