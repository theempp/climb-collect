from pathlib import Path
import os, json, hashlib, zipfile, subprocess, datetime, shutil

PROJECT = Path(r'C:\Users\HOME!\Desktop\climb&collect')
SOURCE = Path(r'C:\Users\HOME!\Desktop\climb-collect-mountain-continuation')
STAMP = datetime.datetime.now(datetime.timezone.utc).strftime('%H%M%SZ')
DEST = Path.home() / 'Documents' / 'ClimbCollect-Recovery' / ('2026-10-24-' + STAMP)
DEST.mkdir(parents=True, exist_ok=False)
ENV = dict(os.environ, GIT_OPTIONAL_LOCKS='0')

def run(root, *args):
    p = subprocess.run(['git', '-C', str(root), *args], capture_output=True, env=ENV)
    if p.returncode: raise RuntimeError(p.stderr.decode(errors='replace'))
    return p.stdout

def digest(path):
    with path.open('rb') as f: return hashlib.file_digest(f, 'sha256').hexdigest()

def enumerate_tree(root):
    files, dirs = [], []
    for base, children, names in os.walk(root, followlinks=False):
        for name in children:
            p = Path(base) / name
            if p.is_symlink() or (hasattr(p, 'is_junction') and p.is_junction()):
                raise RuntimeError('Reparse directory requires explicit preservation: ' + str(p))
            dirs.append(p)
        for name in names:
            p = Path(base) / name
            if p.is_symlink(): raise RuntimeError('Symlink requires explicit preservation: ' + str(p))
            files.append(p)
    return sorted(files), sorted(dirs)

print('Backup destination: ' + str(DEST), flush=True)
(PROJECT / 'evidence/recovery_2026-10-24/location.json').write_text(json.dumps({'backup': str(DEST)}))
metadata = DEST / 'git-metadata'; metadata.mkdir()
roots = {'original': PROJECT, 'mountain': SOURCE, 'lobby': Path(r'C:\Users\HOME!\Desktop\climb&collect-lobby')}
baseline = {}
for label, root in roots.items():
    d = metadata / label; d.mkdir()
    for name, args in [('head', ('rev-parse','HEAD')), ('branch', ('branch','--show-current')),
                       ('status', ('status','--porcelain=v1','-uall')),
                       ('staged', ('diff','--cached','--binary')),
                       ('working', ('diff','--binary'))]:
        (d / (name + '.txt')).write_bytes(run(root, *args))
    idx = Path(run(root, 'rev-parse','--path-format=absolute','--git-path','index').decode().strip())
    shutil.copy2(idx, d / 'index.copy')
    baseline[label] = {'root':str(root), 'head':(d/'head.txt').read_text().strip(),
                       'branch':(d/'branch.txt').read_text().strip(),
                       'staged_sha256':digest(d/'staged.txt'), 'index_sha256':digest(d/'index.copy')}
(metadata/'refs.txt').write_bytes(run(PROJECT, 'show-ref'))
(metadata/'worktrees.txt').write_bytes(run(PROJECT, 'worktree','list','--porcelain'))
(DEST/'baseline.json').write_text(json.dumps(baseline,indent=2))

files, dirs = enumerate_tree(SOURCE)
manifest = {'source':str(SOURCE), 'destination':str(DEST), 'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'files':[], 'directories':[p.relative_to(SOURCE).as_posix() for p in dirs], 'excluded_files':[]}
archive = DEST/'mountain-complete.zip'
with zipfile.ZipFile(archive, 'x', zipfile.ZIP_DEFLATED, compresslevel=1, allowZip64=True) as z:
    for d in dirs: z.writestr(d.relative_to(SOURCE).as_posix()+'/', b'')
    for i,p in enumerate(files):
        rel=p.relative_to(SOURCE).as_posix(); before=p.stat(); h=hashlib.sha256(); size=0
        info=zipfile.ZipInfo.from_file(p,rel);info.compress_type=zipfile.ZIP_DEFLATED
        with p.open('rb') as src,z.open(info,'w',force_zip64=True) as dst:
            while chunk:=src.read(1024*1024): h.update(chunk);dst.write(chunk);size+=len(chunk)
        after=p.stat()
        if (before.st_size,before.st_mtime_ns)!=(after.st_size,after.st_mtime_ns) or size!=before.st_size:
            raise RuntimeError('Source changed while archiving: '+rel)
        manifest['files'].append({'path':rel,'bytes':size,'sha256':h.hexdigest(),'mtime_ns':before.st_mtime_ns})
        if i%250==0: print('Archived',i+1,'/',len(files),flush=True)

print('Verifying every archive entry against recorded SHA-256...',flush=True)
with zipfile.ZipFile(archive) as z:
    for entry in manifest['files']:
        with z.open(entry['path']) as f: actual=hashlib.file_digest(f,'sha256').hexdigest()
        if actual!=entry['sha256']:raise RuntimeError('Archive mismatch: '+entry['path'])

print('Verifying source files stayed unchanged...',flush=True)
after_files,after_dirs=enumerate_tree(SOURCE)
assert [p.relative_to(SOURCE).as_posix() for p in after_files]==[x['path'] for x in manifest['files']]
assert [p.relative_to(SOURCE).as_posix() for p in after_dirs]==manifest['directories']
for entry in manifest['files']:
    if digest(SOURCE/entry['path'])!=entry['sha256']:raise RuntimeError('Source drift: '+entry['path'])

print('Saving self-contained Git history bundle...',flush=True)
bundle=DEST/'climb-collect-all-refs.bundle'
run(PROJECT,'bundle','create',str(bundle),'--all')
verification=run(PROJECT,'bundle','verify',str(bundle));(DEST/'bundle-verify.txt').write_bytes(verification)
manifest.update(file_count=len(files), total_bytes=sum(x['bytes'] for x in manifest['files']),
                archive_sha256=digest(archive),archive_bytes=archive.stat().st_size,
                bundle_sha256=digest(bundle),bundle_bytes=bundle.stat().st_size,
                archive_all_entries_verified=True, source_all_entries_unchanged=True,
                complete=True)
(DEST/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps({k:v for k,v in manifest.items() if k not in ['files','directories']},indent=2),flush=True)
