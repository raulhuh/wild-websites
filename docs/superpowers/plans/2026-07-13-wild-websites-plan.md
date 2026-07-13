# Wild Websites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Autonomer Multi-Website-Builder, der 3 komplett unterschiedliche, visuell extreme Single-File-Websites produziert (Struktur nach Nick Saraevs Fable-5-Video), inklusive echter Bild-/Videogenerierung, Selbst-Verifikation per Screenshot und Live-Deploy auf Netlify.

**Architektur:** Helper-Skripte (Higgsfield-API, Playwright-Screenshot, Netlify-Deploy) + ein Master-Prompt-Template. 3 parallele Claude-Code-`Agent`-Aufrufe (general-purpose, volle Tool-Rechte) bauen je eine Website, nutzen die Helper-Skripte, iterieren 3 Pflicht-Durchgänge, deployen selbst.

**Tech Stack:** Bash + curl (Higgsfield/OpenAI-API-Calls), Node.js + Playwright (Screenshot-Verifikation, `npx playwright`, bereits installiert), Netlify CLI (bereits eingeloggt als raul@hausundhoehe.de), reines HTML/CSS/JS pro Website (kein Framework, Single-File wie im Video).

## Global Constraints

- Alle Secrets ausschließlich aus `.env` laden (`OPENAI_API_KEY`, `HIGSFIELD_API_ID`, `HIGSFIELD_API_SECRET`) — niemals hartkodieren, niemals in Git committen (`.env` ist in `.gitignore`).
- Higgsfield-Basis-URL: `https://platform.higgsfield.ai`. Auth-Header exakt: `Authorization: Key {HIGSFIELD_API_ID}:{HIGSFIELD_API_SECRET}` (Format verifiziert gegen die offizielle Doku, Stand 2026-07-13).
- Jede Website: eine einzelne selbst-enthaltene `index.html` (Styles + Scripts inline), keine externen Build-Schritte — analog zum Video.
- Jede Website durchläuft mindestens 3 Verbesserungs-Durchgänge mit Playwright-Screenshot-Check dazwischen, bevor sie als fertig gilt (siehe Spec).
- Kein Marken-/Konversions-Constraint für dieses Projekt (siehe Spec) — volle kreative Freiheit.
- Output-Ordner: `/Users/raulszekely/Desktop/Programme/wild-websites/site-1/`, `site-2/`, `site-3/`.

---

### Task 1: Credentials-Smoke-Test

**Files:**
- Create: `scripts/smoke-test.sh`

**Interfaces:**
- Produces: Bestätigung, dass `OPENAI_API_KEY`, `HIGSFIELD_API_ID`/`HIGSFIELD_API_SECRET`, Netlify-CLI-Login und Playwright funktionsfähig sind — alle folgenden Tasks setzen das voraus.

- [ ] **Step 1: Skript schreiben**

```bash
cat > scripts/smoke-test.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

echo "== OpenAI =="
curl -sS https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY" | head -c 200
echo

echo "== Higgsfield =="
curl -sS -X POST 'https://platform.higgsfield.ai/higgsfield-ai/soul/standard' \
  --header "Authorization: Key ${HIGSFIELD_API_ID}:${HIGSFIELD_API_SECRET}" \
  --header 'Content-Type: application/json' \
  --data '{"prompt":"a single red circle on white background","aspect_ratio":"1:1","resolution":"720p"}'
echo

echo "== Netlify =="
netlify status

echo "== Playwright =="
npx --yes playwright --version
EOF
chmod +x scripts/smoke-test.sh
```

- [ ] **Step 2: Ausführen**

Run: `cd /Users/raulszekely/Desktop/Programme/wild-websites && ./scripts/smoke-test.sh`
Expected: OpenAI gibt eine Modell-Liste (JSON beginnend mit `{"object": "list"`) zurück. Higgsfield gibt `{"status":"queued","request_id":"..."` zurück (kein `401`/`403`/Fehlertext). Netlify zeigt `Name: Raul Szekely`. Playwright zeigt eine Versionsnummer.

- [ ] **Step 3: Bei Fehler**

401/403 bei Higgsfield → Key-Format prüfen (`Key ID:SECRET`, kein `Bearer`). 401 bei OpenAI → Key in `.env` prüfen. Netlify-Fehler → `netlify login` erneut ausführen.

- [ ] **Step 4: Commit**

```bash
git add scripts/smoke-test.sh
git commit -m "Add credentials smoke test"
```

---

### Task 2: Higgsfield-Helper (Bild + Video generieren)

**Files:**
- Create: `scripts/higgsfield.sh`

**Interfaces:**
- Consumes: `.env` (`HIGSFIELD_API_ID`, `HIGSFIELD_API_SECRET`)
- Produces: zwei Shell-Funktionen, von den Website-Bau-Agenten (Task 6) per `source scripts/higgsfield.sh` nutzbar:
  - `hf_image "<prompt>" "<aspect_ratio>"` → gibt die fertige Bild-URL auf stdout aus
  - `hf_video "<image_url>" "<prompt>" "<duration_seconds>"` → gibt die fertige Video-URL auf stdout aus

- [ ] **Step 1: Skript schreiben**

```bash
cat > scripts/higgsfield.sh << 'EOF'
#!/usr/bin/env bash
# source this file: `source scripts/higgsfield.sh`
_hf_auth() { echo "Authorization: Key ${HIGSFIELD_API_ID}:${HIGSFIELD_API_SECRET}"; }

_hf_poll() {
  local status_url="$1"
  local result
  for i in $(seq 1 60); do
    result=$(curl -sS "$status_url" --header "$(_hf_auth)")
    local status
    status=$(echo "$result" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).status))")
    if [ "$status" = "completed" ]; then echo "$result"; return 0; fi
    if [ "$status" = "failed" ]; then echo "Higgsfield job failed: $result" >&2; return 1; fi
    sleep 5
  done
  echo "Higgsfield poll timeout after 5min" >&2
  return 1
}

hf_image() {
  local prompt="$1" aspect="${2:-16:9}"
  local resp
  resp=$(curl -sS -X POST 'https://platform.higgsfield.ai/higgsfield-ai/soul/standard' \
    --header "$(_hf_auth)" --header 'Content-Type: application/json' \
    --data "$(node -e "console.log(JSON.stringify({prompt:process.argv[1],aspect_ratio:process.argv[2],resolution:'1080p'}))" "$prompt" "$aspect")")
  local status_url
  status_url=$(echo "$resp" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).status_url))")
  local final
  final=$(_hf_poll "$status_url")
  echo "$final" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).images[0].url))"
}

hf_video() {
  local image_url="$1" prompt="$2" duration="${3:-5}"
  local resp
  resp=$(curl -sS -X POST 'https://platform.higgsfield.ai/higgsfield-ai/dop/standard' \
    --header "$(_hf_auth)" --header 'Content-Type: application/json' \
    --data "$(node -e "console.log(JSON.stringify({image_url:process.argv[1],prompt:process.argv[2],duration:Number(process.argv[3])}))" "$image_url" "$prompt" "$duration")")
  local status_url
  status_url=$(echo "$resp" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).status_url))")
  local final
  final=$(_hf_poll "$status_url")
  echo "$final" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).video.url))"
}
EOF
chmod +x scripts/higgsfield.sh
```

- [ ] **Step 2: Testen (echter Call, kostet minimal)**

Run:
```bash
cd /Users/raulszekely/Desktop/Programme/wild-websites
set -a; source .env; set +a
source scripts/higgsfield.sh
hf_image "a single red circle on white background" "1:1"
```
Expected: eine `https://...` Bild-URL auf der letzten Zeile, kein JSON/Fehler.

- [ ] **Step 3: Commit**

```bash
git add scripts/higgsfield.sh
git commit -m "Add Higgsfield image/video generation helper"
```

---

### Task 3: Playwright-Screenshot-Verifikation

**Files:**
- Create: `scripts/screenshot.mjs`

**Interfaces:**
- Consumes: Pfad zu einer lokalen HTML-Datei
- Produces: PNG-Screenshot-Datei + Exit-Code 0 (kein Fehler) / 1 (Konsolen-Fehler oder Ladefehler gefunden) — von Task 6 nach jedem Iterations-Pass genutzt

- [ ] **Step 1: Skript schreiben**

```bash
cat > scripts/screenshot.mjs << 'EOF'
import { chromium } from 'playwright'
import path from 'path'

const [,, htmlPath, outPng] = process.argv
if (!htmlPath || !outPng) {
  console.error('Usage: node scripts/screenshot.mjs <html-file> <output-png>')
  process.exit(2)
}

const errors = []
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } })
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()) })
page.on('pageerror', err => errors.push(String(err)))

await page.goto('file://' + path.resolve(htmlPath))
await page.waitForTimeout(1500) // Zeit für Animationen/Async-Assets
await page.screenshot({ path: outPng, fullPage: true })
await browser.close()

if (errors.length) {
  console.error('Console errors found:\n' + errors.join('\n'))
  process.exit(1)
}
console.log('OK: screenshot saved to ' + outPng)
EOF
```

- [ ] **Step 2: Mit Test-HTML verifizieren**

Run:
```bash
cd /Users/raulszekely/Desktop/Programme/wild-websites
echo '<html><body><h1>Test</h1></body></html>' > /tmp/wild-test.html
npx --yes playwright install chromium
node scripts/screenshot.mjs /tmp/wild-test.html /tmp/wild-test.png
```
Expected: `OK: screenshot saved to /tmp/wild-test.png`, Exit-Code 0, Datei existiert (`ls -la /tmp/wild-test.png`).

- [ ] **Step 3: Fehlerfall verifizieren**

Run:
```bash
echo '<html><body><script>nonexistentFunction()</script></body></html>' > /tmp/wild-test-err.html
node scripts/screenshot.mjs /tmp/wild-test-err.html /tmp/wild-test-err.png; echo "exit: $?"
```
Expected: `Console errors found:` + `exit: 1`

- [ ] **Step 4: Commit**

```bash
git add scripts/screenshot.mjs
git commit -m "Add Playwright screenshot verification helper"
```

---

### Task 4: Netlify-Deploy-Helper

**Files:**
- Create: `scripts/deploy.sh`

**Interfaces:**
- Consumes: Ordnerpfad mit einer fertigen `index.html` (z.B. `site-1/`)
- Produces: Live-URL auf stdout — von Task 6 im letzten Schritt jeder Website genutzt

- [ ] **Step 1: Skript schreiben**

```bash
cat > scripts/deploy.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$1"
if [ ! -f "$DIR/index.html" ]; then
  echo "Fehler: $DIR/index.html existiert nicht" >&2
  exit 1
fi
OUTPUT=$(netlify deploy --dir="$DIR" --prod --json)
echo "$OUTPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).deploy_url || JSON.parse(d).url))"
EOF
chmod +x scripts/deploy.sh
```

- [ ] **Step 2: Mit Platzhalter-Seite testen**

Run:
```bash
cd /Users/raulszekely/Desktop/Programme/wild-websites
mkdir -p /tmp/wild-deploy-test && echo '<html><body>Hello Wild</body></html>' > /tmp/wild-deploy-test/index.html
./scripts/deploy.sh /tmp/wild-deploy-test
```
Expected: eine `https://*.netlify.app`-URL auf stdout.

- [ ] **Step 3: Live-Check**

Run: `curl -sS -o /dev/null -w "%{http_code}\n" "<URL aus Step 2>"`
Expected: `200`

- [ ] **Step 4: Commit**

```bash
git add scripts/deploy.sh
git commit -m "Add Netlify deploy helper"
```

---

### Task 5: Master-Prompt-Template

**Files:**
- Create: `prompts/master-prompt.md`

**Interfaces:**
- Consumes: `{{SITE_NUMBER}}` Platzhalter (wird bei Dispatch in Task 6 ersetzt)
- Produces: vollständiger Auftrags-Prompt für jeden Website-Bau-Agenten in Task 6

- [ ] **Step 1: Datei schreiben**

```bash
cat > prompts/master-prompt.md << 'EOF'
Du baust eine einzelne, radikal andersartige Website als Demonstration extremer
Web-Design-Fähigkeiten. Ziel: `site-{{SITE_NUMBER}}/index.html` im Projektordner
`/Users/raulszekely/Desktop/Programme/wild-websites/`.

FREIHEIT: Wähle Thema, Farben, Schriften, Layout, Techniken (3D via Three.js
per CDN-Script-Tag, Shader, Partikel, Scroll-Animationen, generative Kunst,
Mini-Spiele, Audio-Reaktivität) komplett selbst. Kein Kunde, keine
Markenvorgabe, kein Konversions-Ziel. Baue etwas, das dich selbst
überrascht.

WERKZEUGE (alle im Projektordner, per `source` bzw. direktem Aufruf nutzbar):
- Bilder: `source scripts/higgsfield.sh && hf_image "<detaillierter Prompt>" "<aspect_ratio z.B. 16:9>"` → gibt eine Bild-URL zurück, direkt als <img src> nutzbar.
- Video: `hf_video "<Bild-URL>" "<Bewegungs-Prompt>" <Sekunden 3-10>` → gibt eine Video-URL zurück, direkt als <video src> nutzbar.
- Freie Stock-Fotos (Alternative/Ergänzung): https://images.unsplash.com/photo-... oder https://images.pexels.com/... direkt als <img src> verlinken (keine echte URL raten - nur falls du eine über WebSearch/WebFetch verifiziert hast, sonst Higgsfield/OpenAI-Bild nutzen).
- Screenshot-Check: `node scripts/screenshot.mjs site-{{SITE_NUMBER}}/index.html /tmp/site-{{SITE_NUMBER}}-pass{N}.png` — danach die PNG mit dem Read-Tool ansehen und dein eigenes Ergebnis bewerten.
- Deploy: `./scripts/deploy.sh site-{{SITE_NUMBER}}` → gibt die Live-URL zurück (erst im letzten Schritt aufrufen).

PFLICHT-ABLAUF (mindestens 3 Durchgänge, nicht überspringen):
1. Grundgerüst bauen (index.html mit allem HTML/CSS/JS inline, keine externen
   Build-Schritte). Danach Screenshot-Check: offensichtliche Fehler beheben
   (Overflow, kaputte/leere Bilder, unleserlicher Text, JS-Fehler in der
   Konsole - das Skript meldet die als Exit-Code 1).
2. Design-Komplexität und -Qualität gezielt erhöhen (mehr Tiefe, bessere
   Typografie, echte generierte Bilder/Videos statt Platzhalter). Screenshot-
   Check wiederholen.
3. Politur/Feinschliff (Timing von Animationen, Farbharmonie, Details).
   Letzter Screenshot-Check.

Erst wenn Schritt 3 einen sauberen Screenshot-Check ohne Konsolen-Fehler
zeigt: `./scripts/deploy.sh site-{{SITE_NUMBER}}` ausführen und die
zurückgegebene Live-URL im Abschlussbericht nennen.

ARBEITE KOMPLETT AUTONOM bis zum Deploy - keine Rückfragen zwischendurch.
Melde am Ende: die Live-URL, eine 1-Satz-Beschreibung des Konzepts, welche
Techniken/Werkzeuge du genutzt hast.
EOF
```

- [ ] **Step 2: Commit**

```bash
git add prompts/master-prompt.md
git commit -m "Add master prompt template for site-build agents"
```

---

### Task 6: 3 Websites parallel bauen

**Files:**
- Erzeugt zur Laufzeit: `site-1/index.html`, `site-2/index.html`, `site-3/index.html` (+ evtl. Asset-Unterordner je Site)

**Interfaces:**
- Consumes: `prompts/master-prompt.md` (Task 5), `scripts/higgsfield.sh` (Task 2), `scripts/screenshot.mjs` (Task 3), `scripts/deploy.sh` (Task 4)
- Produces: 3 Live-Netlify-URLs, konsumiert von Task 7

- [ ] **Step 1: `{{SITE_NUMBER}}` für jede Site ersetzen und 3 Agenten in EINER Nachricht parallel dispatchen**

Für jede Site (1, 2, 3): `sed "s/{{SITE_NUMBER}}/N/g" prompts/master-prompt.md` als Prompt an einen `Agent`-Tool-Aufruf mit `subagent_type: general-purpose` übergeben, cwd auf `/Users/raulszekely/Desktop/Programme/wild-websites` gesetzt. Alle 3 Aufrufe in einer einzigen Tool-Nachricht (echte Parallelität, kein sequenzielles Warten).

- [ ] **Step 2: Nach Rückkehr aller 3 Agenten verifizieren**

Für jede Site N:
Run: `test -f site-N/index.html && echo "OK site-N HTML existiert"`
Run: `curl -sS -o /dev/null -w "%{http_code}\n" "<vom Agent gemeldete Live-URL>"`
Expected: `OK site-N HTML existiert` + HTTP `200`

- [ ] **Step 3: Bei Fehlschlag einer Site**

Falls ein Agent keine Live-URL meldet oder `index.html` fehlt: diese eine Site erneut dispatchen (nicht alle 3), gleicher Master-Prompt.

- [ ] **Step 4: Commit**

```bash
git add site-1 site-2 site-3
git commit -m "Add 3 generated wild websites"
```

---

### Task 7: Ergebnis-Zusammenfassung

**Files:**
- Create: `RESULTS.md`

**Interfaces:**
- Consumes: die 3 Live-URLs + Konzept-Beschreibungen aus Task 6
- Produces: menschenlesbare Übersicht für Raul

- [ ] **Step 1: Datei schreiben**

```markdown
# Wild Websites — Pilot-Ergebnisse (2026-07-13)

1. **Site 1** — <1-Satz-Konzept> — <Live-URL>
2. **Site 2** — <1-Satz-Konzept> — <Live-URL>
3. **Site 3** — <1-Satz-Konzept> — <Live-URL>

Genutzte Werkzeuge pro Site: <kurze Liste, z.B. "Higgsfield Bild+Video, Three.js Partikel">
```
(Mit den echten Werten aus Task 6 füllen, keine Platzhalter im finalen Commit.)

- [ ] **Step 2: Alle 3 URLs live verifizieren**

Run: `for u in <URL1> <URL2> <URL3>; do curl -sS -o /dev/null -w "%{http_code} $u\n" "$u"; done`
Expected: dreimal `200 ...`

- [ ] **Step 3: Commit**

```bash
git add RESULTS.md
git commit -m "Add pilot results summary"
```

---

## Self-Review

**Spec-Abdeckung:** Bildgenerierung (Task 2, 6) ✓, Video/Higgsfield (Task 2, 6) ✓, Stock-Foto-Fallback (im Master-Prompt Task 5) ✓, Screenshot-Verifikation (Task 3, im Ablauf Task 5/6) ✓, 3-Pass-Pflicht (Master-Prompt Task 5) ✓, Netlify-Deploy (Task 4, 6) ✓, Output-Struktur `site-1/2/3` (Task 6) ✓, Higgsfield-API vorab recherchiert statt geraten (Constraints, Task 2 - Format gegen offizielle Doku verifiziert) ✓.

**Nicht in diesem Plan (laut Spec bewusst ausgeklammert):** öffentliche `/guide`-Route, Social-Content, Skalierung auf 25 Sites.
