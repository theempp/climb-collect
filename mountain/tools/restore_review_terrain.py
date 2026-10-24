"""Restore the unchanged terrain checkpoint after Studio XML reserialization.

Creates an exclusive backup before replacing only SmoothGrid. Close the target
place before running, and reopen/audit afterward. No original checkpoint writes.
"""
from pathlib import Path
import base64,sys,xml.etree.ElementTree as ET
baseline,target=map(Path,sys.argv[1:3])
assert baseline.resolve()!=target.resolve(),'Never overwrite baseline'
backup=target.with_suffix('.before-terrain-restore.rbxlx')
with backup.open('xb') as out: out.write(target.read_bytes())
def grid(doc):
    return next(p for i in doc.iter('Item') if i.get('class')=='Terrain' for p in i.find('Properties') if p.get('name')=='SmoothGrid')
source=ET.parse(baseline);dest=ET.parse(target)
grid(dest).text=grid(source).text
dest.write(target,encoding='utf-8',xml_declaration=True)
assert base64.b64decode(grid(ET.parse(target)).text)==base64.b64decode(grid(source).text)
print('Exact baseline terrain restored; pre-restoration file preserved at',backup)
