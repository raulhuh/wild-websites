# Setup

Einmalige Einrichtung, bevor `/webseite-bauen` genutzt werden kann.

## 1. Voraussetzungen installieren

- **Node.js** (Version 18+): https://nodejs.org
- **Netlify CLI:**
  ```
  npm install -g netlify-cli
  netlify login
  ```
  Öffnet den Browser zum Login/Registrieren — kostenloser Account reicht.
- **Playwright** (Browser-Automatisierung für den Screenshot-Check):
  ```
  npm install playwright
  npx playwright install chromium
  ```
- **Claude Code**, in diesem Projektordner geöffnet.

## 2. API-Keys besorgen

- **OpenAI** (Bildgenerierung): Account + Key unter
  https://platform.openai.com/api-keys
- **Higgsfield** (Bild-/Videogenerierung): Account unter https://higgsfield.ai
  anlegen, im Cloud-/API-Bereich einen API-Key erzeugen. Du bekommst eine
  **ID** und ein **Secret** — beide brauchst du.
  Ohne Higgsfield-Guthaben funktioniert der Builder trotzdem: er weicht dann
  automatisch auf kostenlose Stockfotos aus, kein Abbruch.

## 3. Keys eintragen

```
cp .env.example .env
```

Dann `.env` öffnen und die drei Werte eintragen:
```
OPENAI_API_KEY=...
HIGSFIELD_API_ID=...
HIGSFIELD_API_SECRET=...
```

`.env` wird nie committed (steht in `.gitignore`) — deine Keys bleiben lokal.

## 4. Prüfen

```
./scripts/setup-check.sh
```

Zeigt an, was schon passt und was noch fehlt. Wenn alles grün ist:

```
./scripts/smoke-test.sh
```

macht einen echten (minimal kostenpflichtigen) End-to-End-Test aller vier
Systeme (OpenAI, Higgsfield, Netlify, Playwright).

## 5. Loslegen

In Claude Code, in diesem Ordner:

```
/webseite-bauen bau mir eine Seite über <dein Thema>
```

oder für ein echtes Unternehmen:

```
/webseite-bauen für https://irgendeine-firma.de, eine moderne Landingpage
```

## Troubleshooting

- **"not_enough_credits" bei Higgsfield:** Guthaben im Higgsfield-Account
  aufladen, oder einfach weiterlaufen lassen — der Agent nutzt dann
  automatisch Stockfotos statt generierter Bilder/Videos.
- **Netlify-Deploys landen alle auf derselben Seite:** sollte nicht
  passieren — `scripts/deploy.sh` vergibt pro Ordnername eine eigene,
  isolierte Netlify-Site. Falls doch: `.netlify/` im Projektordner löschen
  und erneut versuchen.
- **Playwright-Fehler beim Screenshot:** `npx playwright install chromium`
  erneut ausführen (Browser-Binary fehlt oft nach einem `npm install`).
