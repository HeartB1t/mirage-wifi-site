#!/usr/bin/env bash
# Pre-deploy quality gate for the MirageWiFi landing page (static site).
# Runs deterministic checks. Exit 0 = all pass, non-zero = at least one failure.
# No pytest: this is a static HTML/CSS/JS site.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FAIL=0
ok(){ echo "  PASS  $1"; }
ko(){ echo "  FAIL  $1"; FAIL=1; }

echo "== 1. node --check i18n.js =="
if node --check i18n.js 2>/dev/null; then ok "i18n.js syntax"; else ko "i18n.js syntax"; fi

echo "== 2. i18n parity (same key set in en/it/es/fr/de) =="
node -e '
global.window={}; require("./i18n.js"); const I=window.I18N;
const ref=Object.keys(I.en).sort(); let bad=0;
for(const l of Object.keys(I)){ const k=Object.keys(I[l]);
  const miss=ref.filter(x=>!(x in I[l])); const ext=k.filter(x=>!ref.includes(x));
  if(miss.length||ext.length){ bad=1; console.error("    "+l+" miss="+miss.length+" extra="+ext.length);} }
process.exit(bad);
' 2>&1 && ok "5-language parity" || ko "5-language parity"

echo "== 3. no em/en dash (U+2014 / U+2013) =="
D=$(grep -rlP '[\x{2014}\x{2013}]' index.html css/site.css i18n.js modules/ 2>/dev/null)
if [ -z "$D" ]; then ok "no em/en dash"; else ko "em/en dash in: $D"; fi

echo "== 4. no external resource loads (script/style/font/import remote) =="
R=$(grep -rnE '<script[^>]*src="https?://|<link[^>]*href="https?://|@import[^;]*https?://|src:[^;]*url\(https?://|fetch\(["'\'']https?://' index.html css/site.css modules/ 2>/dev/null)
if [ -z "$R" ]; then ok "no remote resources (vanilla, file:// safe)"; else ko "remote resource load found:"; echo "$R"; fi

echo "== 5. GDPR: all MAC addresses locally-administered (2nd nibble in 2/6/A/E) =="
BADMAC=0
for m in $(grep -rhoE '[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}' index.html css/site.css i18n.js modules/ 2>/dev/null | sort -u); do
  n=$(echo "${m:1:1}" | tr 'a-f' 'A-F')
  case "$n" in 2|6|A|E) ;; *) echo "    non-local MAC: $m (2nd nibble $n)"; BADMAC=1;; esac
done
[ "$BADMAC" -eq 0 ] && ok "all MACs locally-administered" || ko "universal/OUI MAC present"

echo "== 6. arsenal card links resolve to existing module pages =="
MISS=0
for h in $(grep -oE 'modules/[0-9]+-[a-z0-9-]+\.html' index.html | sort -u); do
  [ -f "$h" ] || { echo "    missing: $h"; MISS=1; }
done
[ "$MISS" -eq 0 ] && ok "all card links resolve" || ko "broken card link"

echo "== 7. module pages have back-link to the landing =="
BL=$(ls modules/*.html 2>/dev/null | wc -l)
BLOK=$(grep -lE 'href="\.\./index\.html#moduli"' modules/*.html 2>/dev/null | wc -l)
[ "$BL" -gt 0 ] && [ "$BL" -eq "$BLOK" ] && ok "back-link on all $BL module pages" || ko "back-link missing ($BLOK/$BL)"

echo
[ "$FAIL" -eq 0 ] && echo "QUALITY GATE: PASS" || echo "QUALITY GATE: FAIL"
exit $FAIL
