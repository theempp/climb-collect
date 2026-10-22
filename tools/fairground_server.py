"""Local-only source/evidence bridge for Studio review work."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import os, json
ROOT=Path(__file__).resolve().parents[1]
os.chdir(ROOT)
class Handler(SimpleHTTPRequestHandler):
    def do_POST(self):
        name=self.path.removeprefix('/').replace('/','_')
        if not name.endswith('.json'): self.send_error(400); return
        data=self.rfile.read(int(self.headers['Content-Length']))
        json.loads(data)
        (ROOT/'evidence/fairground_2026-10-22'/name).write_bytes(data)
        self.send_response(200); self.end_headers(); self.wfile.write(b'ok')
ThreadingHTTPServer(('127.0.0.1',8772),Handler).serve_forever()
