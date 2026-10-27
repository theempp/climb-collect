"""Home-base promenade review helpers: serve this checkout to Studio and sink evidence JSON. Never writes other checkouts."""
from pathlib import Path
import json, sys
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'evidence/homebase_promenade_2026-10-26'

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw): super().__init__(*a, directory=str(ROOT), **kw)
    def do_POST(self):
        name = self.path.removeprefix('/')
        if '/' in name or chr(92) in name or not name.endswith('.json'):
            self.send_error(400); return
        raw = self.rfile.read(int(self.headers['Content-Length'])); json.loads(raw)
        (EVIDENCE / name).write_bytes(raw)
        self.send_response(200); self.end_headers(); self.wfile.write(b'ok')
    def log_message(self, *a): pass

if __name__ == '__main__':
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    ThreadingHTTPServer(('127.0.0.1', int(sys.argv[1]) if len(sys.argv) > 1 else 8861), Handler).serve_forever()
