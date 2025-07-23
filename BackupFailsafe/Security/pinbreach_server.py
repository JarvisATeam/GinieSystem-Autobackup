from http.server import BaseHTTPRequestHandler, HTTPServer
import json, datetime, os

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == "/pinbreach":
            now = datetime.datetime.now().isoformat()
            data = {
                "event": "PIN_BREACH",
                "timestamp": now,
                "status": "BLOCKED"
            }
            path = os.path.expanduser("~/GinieSystem/Vault/Security/pin_breach.json")
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                json.dump(data, f, indent=2)
            self.send_response(200)
            self.end_headers()

server = HTTPServer(('', 9922), Handler)
print("🔐 Defense Server kjører på http://localhost:9922")
server.serve_forever()
