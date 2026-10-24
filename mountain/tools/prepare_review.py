"""Copy baked XML to a new filename and synchronize source; never overwrite a checkpoint."""
from pathlib import Path
import sys, xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[2]
source,dest=map(Path,sys.argv[1:3])
assert source.resolve()!=dest.resolve() and not dest.exists(), 'Use a new output filename'
doc=ET.parse(source)
found={}
def visit(item,path=''):
    props=item.find('Properties')
    name=next((p.text for p in props if p.get('name')=='Name'),item.get('class'))
    path=f'{path}.{name}' if path else name
    found[path]=item
    for child in item.findall('Item'):visit(child,path)
for item in doc.getroot().findall('Item'):visit(item)
for folder,prefix in [('shared','ReplicatedStorage.MountainShared'),('world','ServerStorage.MountainWorld'),('server','ServerScriptService.MountainServer'),('client','StarterPlayer.StarterPlayerScripts.MountainClient')]:
    for path in (root/'mountain'/folder).glob('*.luau'):
        name=path.name.split('.')[0]
        key=f'{prefix}.{name}'
        item=found.get(key)
        if item is None:
            kind='Script' if '.server.' in path.name else 'LocalScript' if '.client.' in path.name else 'ModuleScript'
            item=ET.SubElement(found[prefix],'Item',{'class':kind,'referent':'MountainContinuation'+folder+name})
            props=ET.SubElement(item,'Properties')
            ET.SubElement(props,'string',{'name':'Name'}).text=name
            ET.SubElement(props,'ProtectedString',{'name':'Source'})
        next(p for p in item.find('Properties') if p.get('name')=='Source').text=path.read_text(encoding='utf-8')
doc.write(dest,encoding='utf-8',xml_declaration=True)
print(dest)
