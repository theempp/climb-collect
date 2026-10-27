"""Minimal stdio MCP client for the Roblox Studio bridge. Usage: rmcp.py list | rmcp.py call <tool> <json-args-file-or-json>"""
import json, os, subprocess, sys, threading, queue

bat = os.path.expandvars(r'%LOCALAPPDATA%\Roblox\mcp.bat')
p = subprocess.Popen(['cmd.exe', '/c', bat], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, cwd=os.path.dirname(bat))
q = queue.Queue()
threading.Thread(target=lambda: [q.put(l) for l in p.stdout], daemon=True).start()

def send(msg):
    p.stdin.write((json.dumps(msg) + '\n').encode()); p.stdin.flush()

def wait(i, timeout):
    while True:
        line = q.get(timeout=timeout)
        try: m = json.loads(line)
        except Exception: continue
        if m.get('id') == i: return m

send({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {'protocolVersion': '2024-11-05', 'capabilities': {}, 'clientInfo': {'name': 'rmcp', 'version': '1'}}})
wait(1, 60)
send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})
import time; time.sleep(float(os.environ.get('RMCP_WARM','8')))
if sys.argv[1] == 'list':
    send({'jsonrpc': '2.0', 'id': 2, 'method': 'tools/list'})
    for t in wait(2, 60)['result']['tools']: print(t['name'], '|', json.dumps(t.get('inputSchema', {}).get('properties', {}))[:300])
else:
    a = sys.argv[3]
    args = json.load(open(a, encoding='utf-8')) if os.path.exists(a) else json.loads(a)
    send({'jsonrpc': '2.0', 'id': 2, 'method': 'tools/call', 'params': {'name': sys.argv[2], 'arguments': args}})
    r = wait(2, float(os.environ.get('RMCP_TIMEOUT', '300')))
    out = sys.argv[4] if len(sys.argv) > 4 else None
    for c in r.get('result', {}).get('content', []) or [r]:
        if c.get('type') == 'image' and out:
            import base64; open(out, 'wb').write(base64.b64decode(c['data'])); print('image ->', out)
        else: print(c.get('text', json.dumps(c))[:20000])
p.kill()
