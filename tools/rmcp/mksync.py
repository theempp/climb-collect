import sys,pathlib
# mksync.py out.luau <repo-relative mountain/client paths...>
out=['local base=game.StarterPlayer.StarterPlayerScripts.MountainClient','local r={}']
for rel in sys.argv[2:]:
    p=pathlib.Path('mountain/client')/rel
    src=p.read_text(encoding='utf-8').replace('\r\n','\n').strip()+'\n'
    parts=rel.split('/');parts[-1]=parts[-1].split('.')[0]
    path=''.join(f":FindFirstChild('{x}')" for x in parts)
    out.append(f"do local m=base{path};assert(m,'{rel}');m.Source=[=====[{src}]=====];table.insert(r,'{parts[-1]}:'..#m.Source) end")
    print(parts[-1],len(src.encode()),file=sys.stderr)
out.append("return table.concat(r,' ')")
open(sys.argv[1],'w',encoding='utf-8').write('\n'.join(out))
