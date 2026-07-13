#!/usr/bin/env bash
# Prüft die Voraussetzungen für Wild Websites, OHNE echte (kostenpflichtige)
# API-Calls zu machen. Für einen echten End-to-End-Test danach zusätzlich
# ./scripts/smoke-test.sh ausführen (das kostet minimal echtes Guthaben).
set -uo pipefail
cd "$(dirname "$0")/.."

ok=0
fail=0

pass() { echo "  ✓ $1"; ok=$((ok+1)); }
warn() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== .env =="
if [ ! -f .env ]; then
  warn ".env fehlt — kopiere .env.example zu .env und trag deine Keys ein: cp .env.example .env"
else
  set -a; source .env; set +a
  [ -n "${OPENAI_API_KEY:-}" ] && pass "OPENAI_API_KEY gesetzt" || warn "OPENAI_API_KEY fehlt in .env"
  [ -n "${HIGSFIELD_API_ID:-}" ] && pass "HIGSFIELD_API_ID gesetzt" || warn "HIGSFIELD_API_ID fehlt in .env"
  [ -n "${HIGSFIELD_API_SECRET:-}" ] && pass "HIGSFIELD_API_SECRET gesetzt" || warn "HIGSFIELD_API_SECRET fehlt in .env"
fi

echo "== Node.js =="
if command -v node >/dev/null 2>&1; then
  pass "node gefunden: $(node --version)"
else
  warn "node nicht gefunden — installieren: https://nodejs.org (Version 18+)"
fi

echo "== Netlify CLI =="
if command -v netlify >/dev/null 2>&1; then
  pass "netlify CLI gefunden"
  netlify_status_output="$(netlify status 2>&1)"
  if echo "$netlify_status_output" | grep -q "Current Netlify User"; then
    pass "Netlify eingeloggt"
  else
    warn "Netlify nicht eingeloggt — ausführen: netlify login"
  fi
else
  warn "netlify CLI fehlt — installieren: npm install -g netlify-cli, danach: netlify login"
fi

echo "== Playwright =="
if npx --yes playwright --version >/dev/null 2>&1; then
  pass "Playwright verfügbar: $(npx --yes playwright --version)"
  echo "    (Browser-Binary ggf. nötig: npx playwright install chromium)"
else
  warn "Playwright nicht verfügbar — installieren: npm install playwright && npx playwright install chromium"
fi

echo
echo "== Ergebnis: $ok OK, $fail offen =="
if [ "$fail" -gt 0 ]; then
  echo "Bitte offene Punkte oben beheben, danach nochmal ausführen."
  exit 1
fi
echo "Alles bereit. Für einen echten End-to-End-Test (kostet minimal): ./scripts/smoke-test.sh"
exit 0
