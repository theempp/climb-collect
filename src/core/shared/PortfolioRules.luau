local R={}
R.rarities={'Common','Uncommon','Rare','Epic','Legendary'}
function R.roster(Species)
 local entries={}
 for _,e in Species.list do table.insert(entries,{id=e.id,rarity=e.rarity,collectible=e.kind=='creature',obtainable=e.obtainable~=false and e.unreleased~=true}) end
 return {entries=entries,replacements=Species.retired or {}}
end
function R.summarize(data,roster)
 local s={collected=0,obtainable=0,percent=0,byRarity={},mutationCount=0}
 for _,r in R.rarities do s.byRarity[r]={collected=0,obtainable=0} end
 local valid,seen,mutations={},{},{}
 for _,e in roster.entries do
  if e.collectible and e.obtainable and s.byRarity[e.rarity] then valid[e.id]=e;s.obtainable+=1;s.byRarity[e.rarity].obtainable+=1 end
 end
 local function canonical(id)
  local visited={} while roster.replacements and roster.replacements[id] and not visited[id] do visited[id]=true;id=roster.replacements[id] end
  return id
 end
 for id,n in data.codex or {} do if n>0 then seen[canonical(id)]=true end end
 for _,b in data.bank or {} do
  local id=canonical(b.species);seen[id]=true
  if type(b.mutation)=='string' and b.mutation~='' then mutations[id..':'..b.mutation]=true end
 end
 for id in seen do local e=valid[id];if e then s.collected+=1;s.byRarity[e.rarity].collected+=1 end end
 for _ in mutations do s.mutationCount+=1 end
 s.percent=s.obtainable>0 and math.floor(s.collected/s.obtainable*1000)/10 or 0
 return s
end
function R.cleanSelections(value,bank)
 value=type(value)=='table' and value or {};local owned,seen={},{};for _,b in bank do owned[b.creatureId]=true end
 local out={titleId=type(value.titleId)=='string' and value.titleId:sub(1,48) or '',frameId=type(value.frameId)=='string' and value.frameId:sub(1,48) or '',showcase={}}
 for _,id in type(value.showcase)=='table' and value.showcase or {} do
  if type(id)=='string' and owned[id] and not seen[id] and #out.showcase<3 then seen[id]=true;table.insert(out.showcase,id) end
 end
 return out
end
return R
