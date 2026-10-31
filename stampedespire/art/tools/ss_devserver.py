"""Local-only dev bridge for Studio (127.0.0.1:8798).
GET /src/<file>    -> prototype/src/<file>      (sync scripts into Studio)
GET /export/<file> -> art/export/<file>         (manifest / data files)
GET /task/<file>   -> art/tools/studio/<file>   (command-bar jobs, run by the one-line runner)
POST /log          -> appends the body to art/tools/devserver.log (Studio reports results here)"""
import http.server, os, sys, time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MAP = {"/src/": os.path.join(ROOT, "prototype", "src"), "/export/": os.path.join(ROOT, "art", "export"),
       "/task/": os.path.join(ROOT, "art", "tools", "studio")}
LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "devserver.log")


class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.path = self.path.split("?")[0]
        for pre, base in MAP.items():
            if self.path.startswith(pre):
                p = os.path.normpath(os.path.join(base, self.path[len(pre):]))
                if p.startswith(base) and os.path.isfile(p):
                    data = open(p, "rb").read()
                    self.send_response(200)
                    self.send_header("Content-Length", str(len(data)))
                    self.end_headers()
                    self.wfile.write(data)
                    return
        self.send_response(404)
        self.end_headers()

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(n).decode("utf-8", "replace")
        with open(LOG, "a", encoding="utf-8") as f:
            f.write("=== %s\n%s\n" % (time.strftime("%H:%M:%S"), body))
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    http.server.ThreadingHTTPServer(("127.0.0.1", 8798), H).serve_forever()
