#!/usr/bin/env python3
"""Headless render gate for the MirageWiFi landing page.
Serves the repo over a local http server (same-origin, like GitHub Pages),
loads the landing and one module page at desktop and mobile widths, and
checks for console/page errors and horizontal overflow. Exit 0 = pass.
Serving over http (not file://) avoids the headless file-origin font CORS
artifact and matches the real deployment. Requires Playwright + Chromium."""
import sys, functools, http.server, socketserver, threading
from playwright.sync_api import sync_playwright

ROOT = "/home/kali/Scrivania/PROGETTI_ATTIVI/mirage-wifi-site"
PORT = 8799
Handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=ROOT)
httpd = socketserver.TCPServer(("127.0.0.1", PORT), Handler)
httpd.allow_reuse_address = True
threading.Thread(target=httpd.serve_forever, daemon=True).start()

BASE = f"http://127.0.0.1:{PORT}"
TARGETS = [(BASE + "/index.html", "landing"),
           (BASE + "/modules/03-evil-twin-captive-portal.html", "module")]
VIEWPORTS = [("desktop", 1440, 900), ("mobile", 390, 844)]

fail = 0
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        for url, label in TARGETS:
            for name, w, h in VIEWPORTS:
                page = browser.new_page(viewport={"width": w, "height": h})
                errors = []
                page.on("console", lambda m, e=errors: e.append(m.text) if m.type == "error" else None)
                page.on("pageerror", lambda exc, e=errors: e.append(str(exc)))
                page.goto(url, wait_until="load")
                page.wait_for_timeout(1500)
                overflow = page.evaluate("document.documentElement.scrollWidth > window.innerWidth + 1")
                sw = page.evaluate("document.documentElement.scrollWidth")
                print(f"[{label} {name} {w}x{h}] console_errors={len(errors)} h_overflow={overflow} scrollWidth={sw}")
                for e in errors[:5]:
                    print("    ERR:", e[:140])
                if errors or overflow:
                    fail = 1
                page.close()
        browser.close()
finally:
    httpd.shutdown()

print("RENDER GATE:", "PASS" if fail == 0 else "FAIL")
sys.exit(fail)
