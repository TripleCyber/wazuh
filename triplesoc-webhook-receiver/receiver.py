"""Receptor de webhooks de prueba (solo red interna del stack).

Imprime en stdout cada mensaje recibido, para verlo en los logs de Coolify.
"""
import datetime
import http.server
import json


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        size = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(size)
        try:
            shown = json.dumps(json.loads(body), ensure_ascii=False, indent=2)
        except ValueError:
            shown = body.decode("utf-8", "replace")
        stamp = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")
        print(f"===== webhook {stamp} {self.path} ({size} bytes)\n{shown}", flush=True)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"received":true}')

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print("receptor de webhooks escuchando en :8080", flush=True)
    http.server.ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
