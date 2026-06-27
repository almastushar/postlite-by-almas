#!/usr/bin/env python3
"""
Postlite local CORS proxy.

Why: browsers block cross-origin requests to APIs that don't send CORS headers
(most internal/VPN endpoints). This little proxy runs ON YOUR MACHINE, calls the
target API server-side (no browser CORS involved), and returns the response with
permissive CORS headers. That lets Postlite work in any NORMAL browser/profile —
no Chrome flag, nothing to close.

Run it on the machine that has the VPN, so it can reach the internal host:

    python proxy.py            # default http://localhost:8010
    python proxy.py 9000       # custom port

Then in Postlite: click "Proxy", tick it on, set the URL to match, Save.

Stdlib only. SSL verification is disabled (like Postman's "disable SSL
verification") so corporate TLS-inspected HTTPS endpoints work.
"""
import sys, ssl, urllib.request, urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DEFAULT_PORT = 8010
TARGET_HEADER = "x-pl-target"
# headers we must not forward verbatim to the target
SKIP = {"host", "content-length", "connection", "x-pl-target",
        "origin", "referer", "accept-encoding"}

_ctx = ssl.create_default_context()
_ctx.check_hostname = False
_ctx.verify_mode = ssl.CERT_NONE


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _cors(self):
        origin = self.headers.get("Origin", "*") or "*"
        self.send_header("Access-Control-Allow-Origin", origin)
        self.send_header("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,HEAD,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", self.headers.get("Access-Control-Request-Headers", "*") or "*")
        self.send_header("Access-Control-Expose-Headers", "*")
        self.send_header("Access-Control-Allow-Credentials", "true")
        self.send_header("Access-Control-Max-Age", "86400")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.send_header("Content-Length", "0")
        self.end_headers()

    def _proxy(self):
        target = self.headers.get(TARGET_HEADER)
        if not target:
            self.send_response(400)
            self._cors()
            self.send_header("Content-Type", "text/plain")
            body = b"Postlite proxy: missing X-PL-Target header"
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        length = int(self.headers.get("Content-Length") or 0)
        data = self.rfile.read(length) if length else None

        req = urllib.request.Request(target, data=data, method=self.command)
        for k, v in self.headers.items():
            if k.lower() not in SKIP:
                req.add_header(k, v)

        try:
            resp = urllib.request.urlopen(req, timeout=120, context=_ctx)
            status, rheaders, payload = resp.status, list(resp.headers.items()), resp.read()
        except urllib.error.HTTPError as e:
            status, rheaders, payload = e.code, list(e.headers.items()), e.read()
        except Exception as e:
            self.send_response(502)
            self._cors()
            self.send_header("Content-Type", "text/plain")
            body = ("Postlite proxy error reaching target:\n%s\n%s" % (target, e)).encode()
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        self.send_response(status)
        drop = {"transfer-encoding", "content-length", "connection",
                "content-encoding", "keep-alive"}
        for k, v in rheaders:
            if k.lower() in drop or k.lower().startswith("access-control-"):
                continue
            self.send_header(k, v)
        self._cors()
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(payload)

    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = do_HEAD = _proxy

    def log_message(self, fmt, *args):
        sys.stderr.write("%s  ->  %s\n" % (self.command, self.headers.get(TARGET_HEADER, "(no target)")))


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
    srv = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print("Postlite proxy running at http://localhost:%d" % port)
    print("In Postlite: click 'Proxy', tick it on, set URL to http://localhost:%d, Save." % port)
    print("Press Ctrl+C to stop.")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped.")


if __name__ == "__main__":
    main()
