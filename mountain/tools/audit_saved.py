"""Audit the named isolated XML review; never writes or modifies a place."""
from pathlib import Path
import xml.etree.ElementTree as ET
import hashlib,json,sys,base64,argparse
root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument('place',nargs='?',type=Path,default=root/'evidence/mountain_2026-10-24/ImpossibleMountain.ArtPassVerified.rbxlx')
parser.add_argument('--terrain-reference',type=Path,help='Explicit saved terrain authority for a deliberate sculpt pass; default stays protected FirstDraft')
args=parser.parse_args();place=args.place
doc=ET.parse(place).getroot()
found={}
counts={}
def visit(item,path=''):
    props=item.find('Properties')
    name=next((p.text for p in props if p.attrib.get('name')=='Name'),item.attrib['class'])
    path=path+'.'+name if path else name
    found[path]=item
    counts[item.attrib['class']]=counts.get(item.attrib['class'],0)+1
    for child in item.findall('Item'):visit(child,path)
for item in doc.findall('Item'):visit(item)
mapping={
 'ReplicatedStorage.MountainShared.Catalog':'shared/Catalog.luau',
 'ReplicatedStorage.MountainShared.Rules':'shared/Rules.luau',
 'ReplicatedStorage.MountainShared.TraversalRules':'shared/TraversalRules.luau',
 'ServerStorage.MountainWorld.TraversalArt':'world/TraversalArt.luau',
 'ServerScriptService.MountainServer.Traversal':'server/Traversal.luau',
 **{'ServerStorage.MountainWorld.'+n:'world/'+n+'.luau' for n in ('Art','Landmarks','World','CreatureDetails','Polish')},
 **{'ServerScriptService.MountainServer.'+n:'server/'+n+'.luau' for n in ('Store','Profiles','Combat','Competition','StudioTests')},
 'ServerScriptService.MountainServer.Main':'server/Main.server.luau',
 'StarterPlayer.StarterPlayerScripts.MountainClient.HUD':'client/HUD.client.luau',
 'StarterPlayer.StarterPlayerScripts.MountainClient.CreatureMotion':'client/CreatureMotion.client.luau',
}
checks=[]
for name in ('Environment','Sculpt'):
    key='ServerStorage.MountainWorld.'+name
    if key in found: mapping[key]='world/'+name+'.luau'
for key,rel in mapping.items():
    item=found[key]
    saved=next(p.text or '' for p in item.find('Properties') if p.attrib.get('name')=='Source')
    expected=(root/'mountain'/rel).read_text(encoding='utf8')
    assert saved.replace('\r\n','\n')==expected.replace('\r\n','\n'),f'Source mismatch: {key}'
    checks.append(key)
assert 'Workspace.ImpossibleMountain' in found
assert not any('MountainQA_' in k or 'BuildRevision' in k for k in found),'Temporary QA object saved'
terrain=found['Workspace.Terrain']
payload=[p for p in terrain.find('Properties') if p.attrib.get('name')=='SmoothGrid']
assert payload and len(payload[0].text or '')>1000,'Missing baked terrain'
terrain_reference=args.terrain_reference or root/'evidence/mountain_2026-10-24/ImpossibleMountain.FirstDraft.rbxlx'
assert terrain_reference.resolve()!=place.resolve(),'Terrain reference must be a separate saved checkpoint'
baseline=ET.parse(terrain_reference)
original=next(p for i in baseline.iter('Item') if i.attrib.get('class')=='Terrain' for p in i.find('Properties') if p.attrib.get('name')=='SmoothGrid')
assert base64.b64decode(payload[0].text)==base64.b64decode(original.text),'Baked terrain differs from explicit authority'
assert len(found['Workspace.ImpossibleMountain.Checkpoints'].findall('Item'))==18
assert len(found['Workspace.ImpossibleMountain.Encounters'].findall('Item'))==42
for k in ('Blossom Gardens','Azure Falls','Sunstone Desert','Violet Crystals','Inferno Heights','Astral Crown'):
    assert 'Workspace.ImpossibleMountain.'+k in found
summary={'place':str(place),'bytes':place.stat().st_size,'sha256':hashlib.sha256(place.read_bytes()).hexdigest(),'matched_sources':len(checks),'kingdoms':6,'encounter_models':42,'checkpoints':18,'terrain_payload_chars':len(payload[0].text),'terrain_reference':str(terrain_reference),'terrain_sha256':hashlib.sha256(base64.b64decode(payload[0].text)).hexdigest(),'classes':counts}
print(json.dumps(summary,indent=2))
