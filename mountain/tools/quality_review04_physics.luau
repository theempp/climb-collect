-- Compare effective collision physics with the immutable Review03 scene record.
-- Review03 has no custom physical properties; expected values come from its saved materials.
local h=game:GetService('HttpService')
local old=h:JSONDecode(h:GetAsync('http://127.0.0.1:8854/evidence/mountain_quality_2026-10-26/review03-final-cold-scene.json'))
local function key(path,cf,size)
 local s=path
 -- Identify duplicate-named parts by position/size; exact transforms are audited separately.
 for i=1,3 do s..=string.format('|%.2f',cf[i]) end
 for _,v in size do s..=string.format('|%.2f',v) end
 return s
end
local expected={}
for _,r in old do if r.collide then
 local k=key(r.path,r.cf,r.size);assert(not expected[k],'Ambiguous collider '..k)
 expected[k]=PhysicalProperties.new(Enum.Material[r.material])
end end
local result={checked=0,errors={},rows={}}
local fields={'Density','Friction','Elasticity','FrictionWeight','ElasticityWeight'}
for _,p in workspace.ImpossibleMountain:GetDescendants() do if p:IsA('BasePart') and p.CanCollide then
 local k=key(p:GetFullName(),{p.CFrame:GetComponents()},{p.Size.X,p.Size.Y,p.Size.Z})
 local e=expected[k];local actual=p.CurrentPhysicalProperties;local row={path=p:GetFullName(),values={}}
 result.checked+=1
 if not e then table.insert(result.errors,p:GetFullName()..': unknown collider') else
  for _,f in fields do
   row.values[f]=actual[f]
   if math.abs(actual[f]-e[f])>1e-6 then table.insert(result.errors,p:GetFullName()..': '..f..' '..actual[f]..' expected '..e[f]) end
  end
  expected[k]=nil
 end
 table.insert(result.rows,row)
end end
for k in expected do table.insert(result.errors,'Missing collider: '..k) end
result.passed=#result.errors==0
return result
