"""Patch runtime Source in a baked Studio binary; preserve every other chunk byte.

Format reference: https://dom.rojo.space/binary.html. Deliberately supports the
ZSTD/raw chunks emitted by this Studio; rejects unsupported compression.
Never edits instances, parents, terrain, settings, or the original input file.
"""
import argparse
import ctypes
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
PREFIXES = {
    'shared': 'ReplicatedStorage.MountainShared',
    'world': 'ServerStorage.MountainWorld',
    'server': 'ServerScriptService.MountainServer',
    'client': 'StarterPlayer.StarterPlayerScripts.MountainClient',
}

def sha(data):
    return hashlib.sha256(data).hexdigest()

def string(data, offset):
    size, = struct.unpack_from('<I', data, offset)
    end = offset + 4 + size
    assert end <= len(data), 'Truncated string'
    return data[offset + 4:end], end

def refs(data, count):
    assert len(data) == count * 4
    result, previous = [], 0
    for i in range(count):
        value = int.from_bytes(bytes(data[i + count * j] for j in range(4)), 'big')
        previous += (value >> 1) ^ -(value & 1)
        result.append(previous)
    return result

class Place:
    def __init__(self, data, zstd_dll):
        assert data[:16] == b'<roblox!\x89\xff\r\n\x1a\n\0\0', 'Expected binary version 0'
        self.header, self.chunks = data[:32], []
        zstd = ctypes.CDLL(str(zstd_dll))
        zstd.ZSTD_decompress.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.c_size_t]
        zstd.ZSTD_decompress.restype = ctypes.c_size_t
        offset = 32
        while offset < len(data):
            begin = offset
            name, compressed, size, reserved = struct.unpack_from('<4sIII', data, offset)
            assert reserved == 0
            offset += 16
            raw = data[offset:offset + (compressed or size)]
            offset += compressed or size
            assert offset <= len(data), 'Truncated chunk'
            if compressed:
                assert raw[:4] == b'\x28\xb5\x2f\xfd', 'Unsupported non-ZSTD compression'
                dest = ctypes.create_string_buffer(size)
                assert zstd.ZSTD_decompress(dest, size, raw, len(raw)) == size
                raw = dest.raw
            self.chunks.append({'name': name, 'raw': raw, 'original': data[begin:offset]})
        assert self.chunks[-1]['name'] == b'END\0' and self.chunks[-1]['raw'] == b'</roblox>'
        self.classes, self.instances, self.parents = {}, {}, {}
        for chunk in self.chunks:
            raw = chunk['raw']
            if chunk['name'] == b'INST':
                cid, = struct.unpack_from('<I', raw)
                name, pos = string(raw, 4)
                fmt = raw[pos]
                count, = struct.unpack_from('<I', raw, pos + 1)
                ids = refs(raw[pos + 5:pos + 5 + count * 4], count)
                assert len(raw) == pos + 5 + count * 4 + (count if fmt else 0)
                self.classes[cid] = {'name': name.decode(), 'ids': ids}
                for ref in ids:
                    assert ref not in self.instances
                    self.instances[ref] = {'class': name.decode()}
            elif chunk['name'] == b'PRNT':
                assert raw[0] == 0
                count, = struct.unpack_from('<I', raw, 1)
                children = refs(raw[5:5 + count * 4], count)
                parents = refs(raw[5 + count * 4:], count)
                self.parents = dict(zip(children, parents))
        for chunk in self.chunks:
            if chunk['name'] != b'PROP':
                continue
            raw = chunk['raw']
            cid, = struct.unpack_from('<I', raw)
            name, pos = string(raw, 4)
            chunk.update(cid=cid, prop=name.decode(), value_offset=pos + 1)
            if name in (b'Name', b'Source'):
                assert raw[pos] == 1
                pos += 1
                values = []
                for ref in self.classes[cid]['ids']:
                    value, pos = string(raw, pos)
                    self.instances[ref][name.decode()] = value.decode('utf-8')
                    values.append(value)
                assert pos == len(raw)
                chunk['values'] = values
        assert len(self.instances) == struct.unpack_from('<I', self.header, 20)[0]
        assert set(self.parents) == set(self.instances)
        self.paths = {}
        for ref in self.instances:
            chain, current = [], ref
            while current != -1:
                assert current not in chain, 'Parent cycle'
                chain.append(current)
                current = self.parents[current]
            path = '.'.join(self.instances[r].get('Name', self.instances[r]['class']) for r in reversed(chain))
            self.paths[ref] = path

    def patch(self, sources):
        found, changed = set(), []
        output = [self.header]
        for chunk in self.chunks:
            if chunk.get('prop') != 'Source':
                output.append(chunk['original'])
                continue
            values = list(chunk['values'])
            for i, ref in enumerate(self.classes[chunk['cid']]['ids']):
                path = self.paths[ref]
                if path in sources:
                    assert path not in found, 'Duplicate runtime path: ' + path
                    found.add(path)
                    value = sources[path].encode('utf-8')
                    if values[i] != value:
                        changed.append(path)
                        values[i] = value
            raw = chunk['raw'][:chunk['value_offset']] + b''.join(struct.pack('<I', len(v)) + v for v in values)
            output.append(chunk['original'] if raw == chunk['raw'] else struct.pack('<4sIII', b'PROP', 0, len(raw), 0) + raw)
        assert found == set(sources), 'Missing runtime paths: ' + repr(set(sources) - found)
        return b''.join(output), changed

def runtime_sources():
    sources = {}
    for folder, prefix in PREFIXES.items():
        for path in sorted((ROOT / 'mountain' / folder).rglob('*.luau')):
            relative = path.relative_to(ROOT / 'mountain' / folder)
            key = '.'.join([prefix, *relative.parts[:-1], path.name.split('.')[0]])
            sources[key] = path.read_text(encoding='utf-8').strip() + '\n'
    return sources

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--zstd-dll', type=Path, required=True)
    parser.add_argument('--exclude', action='append', default=[], help='Runtime path removed from this build (e.g. StudioTests in a phone candidate)')
    args = parser.parse_args()
    assert args.source.resolve() != args.destination.resolve() and not args.destination.exists(), 'Use a new output filename'
    data = args.source.read_bytes()
    original = Place(data, args.zstd_dll)
    assert original.patch({})[0] == data, 'No-op roundtrip changed bytes'
    sources = {k: v for k, v in runtime_sources().items() if k not in args.exclude}
    result, changed = original.patch(sources)
    saved = Place(result, args.zstd_dll)
    actual = {saved.paths[r]: i['Source'] for r, i in saved.instances.items() if 'Source' in i}
    assert all(actual[p] == value for p, value in sources.items()), 'Runtime parity failed'
    assert len(saved.chunks) == len(original.chunks)
    preserved = 0
    for a, b in zip(original.chunks, saved.chunks):
        if a.get('prop') != 'Source':
            assert a['original'] == b['original'], 'Non-Source chunk changed'
            preserved += 1
    legacy = [p for p in actual if any(p.startswith(prefix + '.') for prefix in PREFIXES.values()) and p not in sources]
    allowed_legacy = {'ServerStorage.MountainWorld.' + name for name in (
        'EnvironmentIteration01', 'EnvironmentIteration02', 'EnvironmentIteration03',
        'EnvironmentIteration04', 'SculptIteration06', 'EnvironmentFinish_Experiment11')}
    assert set(legacy) <= allowed_legacy, 'Unexpected runtime sources: ' + repr(set(legacy) - allowed_legacy)
    before = {original.paths[r]: i['Source'] for r, i in original.instances.items() if 'Source' in i}
    assert all(actual[p] == before[p] for p in legacy), 'Historical source changed'
    qa = [p for p in saved.paths.values() if 'MountainQA' in p or 'FreeClimbAcceptance' in p]
    assert not qa, 'Temporary QA objects found'
    report = {
        'input': str(args.source.resolve()), 'input_sha256': sha(data),
        'output': str(args.destination.resolve()), 'output_sha256': sha(result),
        'runtime_sources': len(sources), 'runtime_sha256': {p: sha(v.encode()) for p, v in sources.items()},
        'changed_sources': changed, 'non_source_chunks_preserved': preserved,
        'instances': len(saved.instances), 'temporary_qa': qa, 'historical_sources_preserved': sorted(legacy),
        'free_climb_roots': sorted(p for p in saved.paths.values() if p.count('.') < 3 and 'FreeClimb' in p),
        'limitation': 'Preserves the baked input exactly except Source; Studio cold-open and world acceptance are separate checks.'
    }
    with args.destination.open('xb') as target:
        target.write(result)
    args.destination.with_suffix('.audit.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps({k: v for k, v in report.items() if k not in ('runtime_sha256', 'changed_sources')}, indent=2))

if __name__ == '__main__':
    main()
