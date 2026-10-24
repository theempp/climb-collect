"""Package HUD sources into an isolated copy; prove all world/service properties unchanged."""
from pathlib import Path
import argparse, hashlib, json, uuid, xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]

def name(item):
    return item.find("Properties/*[@name='Name']").text

def child(parent, label, cls='Folder'):
    for node in parent.findall('Item'):
        if name(node) == label:
            return node
    node = ET.SubElement(parent, 'Item', {'class': cls, 'referent': 'RBX'+uuid.uuid4().hex.upper()})
    props = ET.SubElement(node, 'Properties')
    ET.SubElement(props, 'string', {'name':'Name'}).text = label
    return node

def digest(node):
    return hashlib.sha256(ET.tostring(node)).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('baseline', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    assert args.baseline.resolve() != args.output.resolve(), 'Never overwrite baseline'
    tree = ET.parse(args.baseline); doc = tree.getroot()
    # These whole service trees must be byte-equivalent after XML parsing/serialization.
    protected = {name(n): digest(n) for n in doc.findall('Item') if name(n) not in ('ReplicatedStorage','ServerScriptService','StarterPlayer')}
    mapping = {'shared': ('ReplicatedStorage','MountainShared'), 'server': ('ServerScriptService','MountainServer'), 'client': ('StarterPlayer','StarterPlayerScripts','MountainClient')}
    matched = []
    for directory, path in mapping.items():
        dest = doc
        for label in path:
            dest = child(dest, label)
        for source in sorted((ROOT/'mountain'/directory).rglob('*.luau')):
            rel = source.relative_to(ROOT/'mountain'/directory)
            parent = dest
            for folder in rel.parts[:-1]: parent = child(parent, folder)
            stem = source.stem
            cls = 'LocalScript' if stem.endswith('.client') else 'Script' if stem.endswith('.server') else 'ModuleScript'
            label = stem.removesuffix('.client').removesuffix('.server')
            node = child(parent, label, cls)
            assert node.attrib['class'] == cls, (label, node.attrib['class'], cls)
            props = node.find('Properties')
            field = props.find("*[@name='Source']")
            if field is None: field = ET.SubElement(props, 'ProtectedString', {'name':'Source'})
            field.text = source.read_text(encoding='utf-8-sig')
            matched.append(('.'.join(path+rel.parts[:-1]+(label,)), source, field.text))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    tree.write(args.output, encoding='utf-8', xml_declaration=True)
    reread = ET.parse(args.output).getroot()
    for n in reread.findall('Item'):
        if name(n) in protected: assert digest(n) == protected[name(n)], 'Protected service changed: '+name(n)
    def resolve(path):
        n = reread
        for part in path.split('.'): n = next(c for c in n.findall('Item') if name(c)==part)
        return n
    for path, source, expected in matched:
        assert resolve(path).find("Properties/*[@name='Source']").text == expected
    report = {'baseline':str(args.baseline.resolve()),'baseline_sha256':hashlib.sha256(args.baseline.read_bytes()).hexdigest(),'output':str(args.output.resolve()),'sha256':hashlib.sha256(args.output.read_bytes()).hexdigest(),'matched_runtime_sources':len(matched),'protected_services':protected,'bytes':args.output.stat().st_size}
    args.output.with_suffix('.audit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    print(json.dumps(report,indent=2))

if __name__ == '__main__': main()
