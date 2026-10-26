-- Read-only exact scene records for saved/cold-open identity; no QA instance creation.
local rows={}
for _,p in workspace:GetDescendants() do
 if p:IsDescendantOf(workspace.ImpossibleMountain) and p:IsA('BasePart') then
  table.insert(rows,{path=p:GetFullName(),class=p.ClassName,cf={p.CFrame:GetComponents()},size={p.Size.X,p.Size.Y,p.Size.Z},color={p.Color.R,p.Color.G,p.Color.B},material=p.Material.Name,transparency=p.Transparency,collide=p.CanCollide,query=p.CanQuery,touch=p.CanTouch,anchored=p.Anchored,shadow=p.CastShadow,shape=if p:IsA('Part') then p.Shape.Name else ''})
 end
end
return rows
