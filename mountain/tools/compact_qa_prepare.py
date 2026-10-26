from pathlib import Path
root=Path(__file__).resolve().parent
raid=(root/'quality_review06_raid.client.luau').read_text()
raid=raid.replace('local function walk(q,label,verticalTolerance)', '''local function compact(q)
 if q.Z> -210 then return q end
 local result=Vector3.new(4096,16,-210)+(q-Vector3.new(4096,16,-210))*.85
 if q.X==4038 or q.X==4154 then result=Vector3.new(q.X,result.Y,result.Z) end
 return result
end
local function walk(q,label,verticalTolerance)
 q=compact(q)''')
raid=raid.replace('h:MoveTo(Vector3.new(4038,403,-1336))','h:MoveTo(compact(Vector3.new(4038,403,-1336)))')
raid=raid.replace('rr.Position.Y<y+1','rr.Position.Y<16+(y-16)*.85+1')
raid=raid.replace('local failed=false','local failed=false;local messages={}')
raid=raid.replace("if kind=='state' then state=data end", "if kind=='state' then state=data elseif kind=='toast' then table.insert(messages,{elapsed=os.clock()-started,text=data}) end")
raid=raid.replace('log=log,elapsed=', 'log=log,messages=messages,elapsed=')
(root/'compact_raid.client.luau').write_text(raid)
walk=(root/'quality_walk.client.luau').read_text()
walk=walk.replace('local z=-210-(k-1)*200-d','local z=-210-((k-1)*200+d)*.85; x=4096+(x-4096)*.85')
walk=walk.replace('   p:RequestStreamAroundAsync(Vector3.new(4096,16+(k-1)*64,-210-(k-1)*200),3)','')
walk=walk.replace('  p:RequestStreamAroundAsync(Vector3.new(4096,16+(k-1)*64,-210-(k-1)*200),3)','')
(root/'compact_walk.client.luau').write_text(walk)
