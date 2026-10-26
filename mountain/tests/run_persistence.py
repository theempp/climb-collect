from service_harness import *
body += '\n' + (ROOT/'mountain/tests/run_persistence.luau').read_text()
with tempfile.TemporaryDirectory(prefix='run-persistence-') as directory:
    target=Path(directory)/'tests.luau'
    target.write_text(body,encoding='utf8')
    subprocess.run([str(CLI),str(target)],check=True)
