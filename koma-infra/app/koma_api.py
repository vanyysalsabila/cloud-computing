#!/usr/bin/env python3
"""Aplikasi API koma (koma_api.py) untuk praktikum Komputasi Awan.

Menyediakan endpoint:
  - GET /health  -> 200 {"status": "ok", "peran": ..., "versi": ...}
  - GET /versi   -> 200 {"versi": ..., "peran": ...}
  - GET /lambat  -> 200 {"status": "ok", "latency_ms": ...} (dengan jeda ?ms=...)
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse


class KomaApiHandler(BaseHTTPRequestHandler):
    peran: str = "api"
    versi: str = "v1"

    def _kirim_json(self, kode: int, data: dict) -> None:
        badan = json.dumps(data, indent=2).encode("utf-8")
        self.send_response(kode)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(badan)))
        self.end_headers()
        self.wfile.write(badan)

    def do_GET(self) -> None:  # noqa: N802
        u = urlparse(self.path)
        jalur = u.path.rstrip("/") or "/"

        if jalur == "/health":
            self._kirim_json(200, {
                "status": "ok",
                "peran": self.peran,
                "versi": self.versi,
            })
        elif jalur == "/versi":
            self._kirim_json(200, {
                "versi": self.versi,
                "peran": self.peran,
            })
        elif jalur == "/lambat":
            qs = parse_qs(u.query)
            ms = 500
            if "ms" in qs:
                try:
                    ms = max(0, min(10000, int(qs["ms"][0])))
                except ValueError:
                    pass
            time.sleep(ms / 1000.0)
            self._kirim_json(200, {
                "status": "ok",
                "latency_ms": ms,
                "versi": self.versi,
            })
        else:
            self._kirim_json(404, {
                "galat": "tidak ditemukan",
                "jalur": jalur,
            })

    def log_message(self, format: str, *args) -> None:
        # Format log singkat ke stderr
        sys.stderr.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {self.address_string()} - {format % args}\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="koma-api HTTP server")
    parser.add_argument("--port", type=int, default=int(os.environ.get("KOMA_PORT", "80")), help="Port HTTP (bawaan 80)")
    parser.add_argument("--versi", default=os.environ.get("KOMA_VERSI", "v1"), help="Versi aplikasi (bawaan v1)")
    parser.add_argument("--peran", default=os.environ.get("KOMA_PERAN", "api"), help="Peran layanan (bawaan api)")
    args = parser.parse_args()

    KomaApiHandler.versi = args.versi
    KomaApiHandler.peran = args.peran

    server_address = ("", args.port)
    httpd = HTTPServer(server_address, KomaApiHandler)
    sys.stderr.write(f"koma-api berjalan di port {args.port} (peran={args.peran}, versi={args.versi})\n")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        sys.stderr.write("\nkoma-api dihentikan.\n")
    finally:
        httpd.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
