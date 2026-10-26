-- Read-only snapshot; caller chooses the evidence filename.
local function value(v)
 local kind=typeof(v)
 if kind=='CFrame' then return {v:GetComponents()} end
 if kind=='Vector3' then return {v.X,v.Y,v.Z} end
 if kind=='Color3' then return {v.R,v.G,v.B} end
 if kind=='EnumItem' then return tostring(v) end
 if kind=='Instance' then return v:GetFullName() end
 return v
end
local function record(p)
 local r={class=p.ClassName,name=p.Name,attributes=p:GetAttributes()}
 local props={}
 if p:IsA('BasePart') then props={'CFrame','Size','Color','Material','Transparency','CanCollide','CanTouch','CanQuery','Anchored','CastShadow','CollisionGroup'}
 elseif p:IsA('ProximityPrompt') then props={'ActionText','ObjectText','HoldDuration','MaxActivationDistance','RequiresLineOfSight','Enabled'}
 elseif p:IsA('DataModelMesh') then props={'Scale','Offset'}
 elseif p:IsA('TextLabel') then props={'Text','TextColor3','TextSize','Font'} end
 if p:IsA('SpecialMesh') then table.insert(props,'MeshId');table.insert(props,'TextureId');table.insert(props,'MeshType') end
 for _,key in props do r[key]=value(p[key]) end
 r.children={};for _,child in p:GetChildren() do table.insert(r.children,record(child)) end
 table.sort(r.children,function(a,b) if a.name==b.name then return game.HttpService:JSONEncode(a)<game.HttpService:JSONEncode(b) end;return a.name<b.name end)
 return r
end
local world=workspace.ImpossibleMountain
local result={protected={},sections={},lighting={},counts={}}
for _,p in workspace:GetChildren() do
 if p~=world and not p:IsA('Terrain') and not p:IsA('Camera') then result.protected[p.Name]=record(p) end
end
result.protected.ImpossibleMountain={}
for _,p in world:GetChildren() do if not p:GetAttribute('Kingdom') then table.insert(result.protected.ImpossibleMountain,record(p)) end end
for _,key in {'Ambient','OutdoorAmbient','Brightness','ClockTime','GeographicLatitude','GlobalShadows','EnvironmentDiffuseScale','EnvironmentSpecularScale','ExposureCompensation'} do result.lighting[key]=value(game.Lighting[key]) end
for _,section in world:GetChildren() do if section:IsA('Folder') and section:GetAttribute('Kingdom') then
 local n,c=0,0;local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,p in section:GetDescendants() do if p:IsA('BasePart') then n+=1;if p.CanCollide then c+=1 end
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do local q=p.CFrame*Vector3.new(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2);lo=lo:Min(q);hi=hi:Max(q) end end end
 end end
 result.sections[section.Name]={parts=n,colliders=c,min=value(lo),max=value(hi)}
end end
for _,p in workspace:GetDescendants() do result.counts[p.ClassName]=(result.counts[p.ClassName] or 0)+1 end
return result
