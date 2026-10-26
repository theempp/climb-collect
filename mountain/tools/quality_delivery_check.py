"""Verify the local handoff against recorded, independently exercised Studio evidence."""
import hashlib
import json
from pathlib import Path
from PIL import Image
from quality_evidence import canonical

ROOT = Path(__file__).resolve().parents[2]
EV = ROOT / 'evidence/mountain_quality_2026-10-26'

def read(name):
    return canonical(json.loads((EV / (name + '.json')).read_text(encoding='utf-8')))

def performance():
    before, after = read('baseline-performance'), read('final-performance')
    assert len(before['views']) == len(after['views']) == 7
    rows = []
    for b, a in zip(before['views'], after['views']):
        assert b['id'] == a['id'] and b['viewport'] == a['viewport']
        rows.append({'view': a['id'], 'before': {k: b[k] for k in ('medianMs', 'p95Ms')},
                     'after': {k: a[k] for k in ('medianMs', 'p95Ms')},
                     'before_render': b['triangles']['Sizes'], 'after_render': a['triangles']['Sizes']})
    report = {'scope': '120 frame samples per matched Studio camera, 1365x768, desktop simulator; render counts depend on streaming residency.',
              'rows': rows,
              'limitations': ['Not a physical-phone or uncapped GPU budget measurement.',
                 'First cold run used for this comparison; repeated run confirms regional frame times, but its whole view had only572 triangles and is excluded as incompletely streamed.',
                 'Native-small-mesh experiment was not adopted: background throttling and incomplete streaming confounded its samples.'],
              'decision': 'Retain v2: desktop median remains near16.7ms and p95 under18.3ms. Whole-view observed triangles rise122270 to307622 and draws256 to304; hardware cost remains a deployment gate.'}
    (EV / 'performance-comparison.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    return report

def main():
    report = performance()
    names = [v['id'] for v in read('views')] + [f'phone-section-{k}-terrace' for k in range(1, 7)]
    images = []
    for side in ('before', 'after'):
        for name in names:
            path = EV / side / (name + '.jpg')
            data = path.read_bytes()
            with Image.open(path) as image:
                assert image.format == 'JPEG'
                assert image.size == ((671, 302) if name.startswith('phone-') else (1565, 880))
                image.verify()
            images.append({'path': path.relative_to(ROOT).as_posix(), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
    assert len(images) == 52
    assert read('cold-geometry')['passed'] and read('cold-geometry')['checks'] == 10628
    assert read('cold-raid-and-hazards')['passed'] and read('cold-raid-and-hazards')['done']
    assert read('cold-phone-acceptance')['passed']
    identity = read('cold-scene-identity')
    assert identity['passed'] and identity['exact'] and not identity['differences']
    assert read('cold-source-parity')['passed'] and not read('cold-source-parity')['mismatches']
    assert read('final-collision-preservation')['identical_to_naturally_tested_layout']
    multiplayer = read('multiplayer-final')
    assert multiplayer['done'] and multiplayer['ok'] and not multiplayer['failures']
    regression = read('final-regression')
    assert len(regression['suites']) == 26 and len(regression['compiles']) == 77
    assert all(x['exit'] == 0 for x in regression['suites'] + regression['compiles'])
    integrity = read('final-file-integrity')
    assert hashlib.sha256(Path(integrity['place']).read_bytes()).hexdigest() == integrity['sha256']
    assert not integrity['source_mismatches'] and not integrity['terrain_drift'] and not integrity['temporary_qa']
    for n in ('final-scene-preservation', 'cold-scene-preservation'):
        s = read(n)
        assert s['protected_equal'] and s['lighting_equal']
    result = {'passed': True, 'images': images, 'geometry_checks': 10628, 'runtime_compiles': 77,
              'regression_suites': 26, 'multiplayer_checks': multiplayer['checks'], 'place_sha256': integrity['sha256'],
              'performance_rows': len(report['rows']), 'scope': 'Local evidence and current artifact; no hosted-save, physical-device or owner aesthetic acceptance.'}
    (EV / 'delivery-verification.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps({k: v for k, v in result.items() if k != 'images'}, indent=2))

if __name__ == '__main__':
    main()
