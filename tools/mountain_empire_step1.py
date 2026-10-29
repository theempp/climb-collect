"""Create a separate, script-free Step 1 place. Never reads/writes legacy places."""
from pathlib import Path
import xml.etree.ElementTree as E
import math, json, hashlib, shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'redesign'/'step1'
OUT.mkdir(parents=True,exist_ok=True)
DEST=OUT/'MountainEmpire.Step1.Blockout.rbxlx'
assert not DEST.exists(), 'Refuse to overwrite an existing review place'
root=E.Element('roblox',{'version':'4'})
E.SubElement(root,'External').text='null'
E.SubElement(root,'External').text='nil'
counter=0
def prop(p,t,n,v):
    e=E.SubElement(p,t,{'name':n}); e.text=str(v); return e
def item(parent,cls,name):
    global counter
    counter+=1
    e=E.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{counter}'})
    p=E.SubElement(e,'Properties'); prop(p,'string','Name',name)
    return e,p
def vec(p,n,v):
    e=E.SubElement(p,'Vector3',{'name':n})
    for a,b in zip(('X','Y','Z'),v): E.SubElement(e,a).text=str(b)
def cf(p,pos,angle=0):
    e=E.SubElement(p,'CoordinateFrame',{'name':'CFrame'})
    c,s=math.cos(angle),math.sin(angle)
    for a,b in zip(('X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'),(*pos,1,0,0,0,c,-s,0,s,c)): E.SubElement(e,a).text=str(b)
def color(p,n,rgb):
    e=E.SubElement(p,'Color3',{'name':n})
    for a,b in zip(('R','G','B'),rgb): E.SubElement(e,a).text=str(b/255)
parts=[]
def part(parent,name,size,pos,rgb=(162,174,163),angle=0,cls='Part',collide=True):
    e,p=item(parent,cls,name); vec(p,'size',size); cf(p,pos,angle)
    color(p,'Color',rgb)
    for n,v in [('Anchored','true'),('CanCollide',str(collide).lower()),('CanTouch','false'),('CastShadow','true')]: prop(p,'bool',n,v)
    prop(p,'token','Material',256); prop(p,'token','TopSurface',0);prop(p,'token','BottomSurface',0)
    if cls=='SpawnLocation': prop(p,'bool','Neutral','true');prop(p,'float','Duration',0)
    parts.append(dict(name=name,size=size,position=pos,angle=angle))
    return e
ws,wsp=item(root,'Workspace','Workspace');prop(wsp,'bool','StreamingEnabled','true')
world,_=item(ws,'Model','MountainEmpire_Step1')
plots,_=item(world,'Folder','SanctuaryPlots')
for i in range(8):
    x=-413+118*i
    f,_=item(plots,'Model',f'Plot_{i+1:02}')
    part(f,'Plot_110x120',(110,2,120),(x,-1,60),(126+4*(i%2),157,132))
    part(f,'RearLodgeFootprint_35x30',(35,.2,30),(x,.1,100),(191,171,143))
    # Low massing marker: no architecture or interiors.
    for dx in (-17.25,17.25): part(f,'LodgeFootprintEdge',(.5,.6,30),(x+dx,.4,100),(215,196,164))
    for z in (85.25,114.75): part(f,'LodgeFootprintEdge',(35,.6,.5),(x,.4,z),(215,196,164))
    part(f,'Spawn',(6,.2,6),(x,.1,76),(141,170,146),cls='SpawnLocation')
    for dx in (-54.75,54.75): part(f,'PlotEdge',(.5,.1,120),(x+dx,.05,60),(214,223,208))
    part(f,'FrontEdge',(110,.1,.5),(x,.05,.25),(214,223,208))
    part(f,'RearEdge',(110,.1,.5),(x,.05,119.75),(214,223,208))
    if i<7: part(world,f'Buffer_{i+1}_8studs',(8,2,120),(x+59,-1,60),(102,129,109))
access,_=item(world,'Folder','EssentialAccess')
part(access,'AccessGround',(956,4,78),(0,-2,-39),(112,139,117))
part(access,'WestDirectAccess',(430,.16,12),(-253,.08,-10),(184,184,169))
part(access,'EastDirectAccess',(430,.16,12),(253,.08,-10),(184,184,169))
for i in range(8): part(access,f'PlotLink_{i+1}',(12,.16,16),(-413+118*i,.08,-4),(184,184,169))
terrace,_=item(world,'Folder','GatewayTerrace')
part(terrace,'Terrace_Surface16',(220,20,48),(0,6,-90),(154,165,160))
# Ramps: top surface exactly y=0 at z=-18 and y=16 at z=-66.
theta=math.atan(16/48)
for x in (-72,72):
    part(terrace,'Ramp_20wide_18deg',(20,1,math.hypot(48,16)),(x,8-.5*math.cos(theta),-42-.5*math.sin(theta)),(190,188,171),theta)
for k in range(32):
    height=(k+1)*.5
    part(terrace,f'WideStep_{k+1:02}',(40,height,1.5),(0,height/2,-18-(k+.5)*1.5),(190,188,171))
gates,_=item(world,'Folder','ThreeGates_NoGameplay')
for name,x,width,height in [('West',-72,45,29),('Center',0,60,38),('East',72,45,29)]:
    f,_=item(gates,'Model',name)
    for sign in (-1,1): part(f,'Pier',(5,height,8),(x+sign*(width/2-2.5),16+height/2,-91),(146,165,171))
    part(f,'Lintel',(width,5,8),(x,16+height-2.5,-91),(169,188,193))
terrain,_=item(world,'Folder','TerrainMassing_NoLandscaping')
for sign in (-1,1):
    part(terrain,'BasinSideLower',(48,32,244),(sign*502,8,16),(109,132,122))
    part(terrain,'BasinSideUpper',(68,66,280),(sign*552,25,0),(119,139,133))
part(terrain,'RearTerraceLower',(1024,22,32),(0,5,141),(115,139,119))
part(terrain,'RearTerraceUpper',(1136,42,40),(0,15,177),(124,146,130))
for sign in (-1,1):
    part(terrain,'GateFlankTerrace',(360,36,70),(sign*300,10,-101),(118,143,128))
    part(terrain,'GateFlankUpper',(390,70,80),(sign*315,27,-176),(131,151,143))
part(terrain,'BeyondGateLanding',(220,20,60),(0,6,-144),(145,164,151))
for x,w,h,z in [(-380,270,180,-290),(-180,250,260,-350),(50,310,360,-420),(290,290,280,-360),(460,220,185,-290)]:
    part(terrain,'MountainSilhouette',(w,h,220),(x,h/2-8,z),(134,153,154),cls='WedgePart')
lighting,lp=item(root,'Lighting','Lighting');prop(lp,'float','ClockTime',13.5);prop(lp,'float','Brightness',2.5)
color(lp,'Ambient',(133,145,156)); color(lp,'OutdoorAmbient',(155,167,176));prop(lp,'bool','GlobalShadows','true')
players,pp=item(root,'Players','Players');prop(pp,'int','MaxPlayers',8)
sp,spp=item(root,'StarterPlayer','StarterPlayer');prop(spp,'float','CharacterWalkSpeed',16);prop(spp,'float','CharacterMaxSlopeAngle',45)
item(root,'ServerStorage','ServerStorage');item(root,'ReplicatedStorage','ReplicatedStorage');item(root,'ServerScriptService','ServerScriptService')
E.indent(root)
E.ElementTree(root).write(DEST,encoding='utf-8',xml_declaration=True)
(OUT/'geometry-manifest.json').write_text(json.dumps(parts,indent=2))
shutil.copy2(DEST,OUT/'MountainEmpire.Step1.Checkpoint.rbxlx')
print(json.dumps({'place':str(DEST),'parts':len(parts),'sha256':hashlib.sha256(DEST.read_bytes()).hexdigest()}))
