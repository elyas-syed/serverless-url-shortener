#!/usr/bin/env python3
"""Local UI server with a mock API for frontend development.

Serves files from web/ and implements enough of POST/GET /api/links
to exercise the shorten + QR flow without AWS.

Does not implement GET /{slug} redirects — use a deployed app_url to
verify phone scans of generated QR codes.

Usage:
  make serve
  # then open http://127.0.0.1:8080
"""

from __future__ import annotations

import argparse
import json
import os
import re
import socket
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
WEB_ROOT = ROOT / "web"
HOST = "127.0.0.1"
DEFAULT_PORT = int(os.environ.get("PORT", "8080"))

# In-memory store: slug -> link dict
LINKS: dict[str, dict] = {}

SLUG_RE = re.compile(r"^[a-zA-Z0-9_-]{3,32}$")
RESERVED = {
    "api",
    "health",
    "admin",
    "links",
    "docs",
    "index.html",
    "favicon.ico",
    "static",
    "assets",
}


def _json(handler: SimpleHTTPRequestHandler, status: int, payload: dict) -> None:
    body = json.dumps(payload).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def _read_json(handler: SimpleHTTPRequestHandler) -> dict | None:
    length = int(handler.headers.get("Content-Length", "0") or "0")
    raw = handler.rfile.read(length) if length else b"{}"
    try:
        return json.loads(raw.decode("utf-8") or "{}")
    except json.JSONDecodeError:
        return None


def _base_url(handler: SimpleHTTPRequestHandler) -> str:
    host = handler.headers.get("Host", f"{HOST}:{DEFAULT_PORT}")
    return f"http://{host}"


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_ROOT), **kwargs)

    def log_message(self, fmt: str, *args) -> None:
        print(f"[{self.log_date_time_string()}] {args[0]}")

    def do_GET(self) -> None:  # noqa: N802
        path = urlparse(self.path).path

        if path == "/health":
            return _json(self, 200, {"status": "ok"})

        match = re.fullmatch(r"/api/links/([^/]+)", path)
        if match:
            slug = match.group(1)
            item = LINKS.get(slug)
            if not item:
                return _json(self, 404, {"error": "Link not found."})
            now = int(time.time())
            return _json(
                self,
                200,
                {
                    **item,
                    "expired": now >= item["expires_at"],
                },
            )

        return super().do_GET()

    def do_POST(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path != "/api/links":
            return _json(self, 404, {"error": "Not found."})

        body = _read_json(self)
        if body is None:
            return _json(self, 400, {"error": "Invalid JSON body."})

        long_url = str(body.get("url", "")).strip()
        if not long_url.startswith(("http://", "https://")):
            return _json(self, 400, {"error": "URL must start with http:// or https://."})

        slug = str(body.get("slug", "")).strip()
        if slug:
            if not SLUG_RE.match(slug) or slug.lower() in RESERVED:
                return _json(self, 400, {"error": "Invalid slug."})
        else:
            slug = f"link-{int(time.time()) % 100000:05d}"

        if slug in LINKS:
            return _json(self, 409, {"error": "Slug already exists."})

        now = int(time.time())
        expires_in_days = int(body.get("expires_in_days", 3) or 3)
        base = _base_url(self)
        item = {
            "slug": slug,
            "long_url": long_url,
            "short_url": f"{base}/{slug}",
            "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now)),
            "expires_at": now + expires_in_days * 86400,
            "click_count": 0,
            "is_active": True,
        }
        LINKS[slug] = item
        return _json(self, 201, item)


def _port_available(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind((HOST, port))
        except OSError:
            return False
    return True


def _pick_port(preferred: int) -> int:
    if _port_available(preferred):
        return preferred
    for port in range(preferred + 1, preferred + 20):
        if _port_available(port):
            print(f"Port {preferred} is in use; using {port} instead.")
            return port
    raise SystemExit(
        f"Ports {preferred}-{preferred + 19} are in use.\n"
        f"Stop the other server (Ctrl+C), or run: PORT=8090 make serve"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Local UI + mock API server")
    parser.add_argument(
        "--port",
        type=int,
        default=DEFAULT_PORT,
        help=f"Port to listen on (default: {DEFAULT_PORT}, or PORT env)",
    )
    args = parser.parse_args()

    if not WEB_ROOT.is_dir():
        raise SystemExit(f"Missing web root: {WEB_ROOT}")

    port = _pick_port(args.port)
    server = ThreadingHTTPServer((HOST, port), Handler)
    print(f"Local UI + mock API: http://{HOST}:{port}", flush=True)
    print("POST /api/links is mocked in-memory (not AWS). Ctrl+C to stop.", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        server.server_close()


if __name__ == "__main__":
    main()
