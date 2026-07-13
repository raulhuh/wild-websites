---
name: webseite-bauen
description: 'Baut eine einzelne, technisch/visuell extreme Website nach der "Wild Websites"-Architektur (autonomer Fable-5-Agent, echte Bild-/Video-Generierung via Higgsfield, Playwright-Screenshot-Selbstverifikation, 3 Pflicht-Verbesserungsdurchgänge, automatischer Netlify-Deploy) — exakt der Prozess aus docs/superpowers/plans/2026-07-13-wild-websites-plan.md. Erkennt automatisch ob es ein freies Kunst-/Technik-Demo-Projekt ist oder eine echte Business-Website (dann: recherchiert zuerst echte Fakten/Logo/Farben der Firma, keine erfundenen Preise/Namen). Triggers: "/webseite-bauen <Beschreibung>", "#Webseite <Beschreibung>", "bau eine webseite für X", "webseite bauen für X", "mach mir sowas wie site-1 aber für X".'
---

# Webseite bauen — Wild-Websites-Prozess als Command

> Ein Satz rein, eine live deployte Website raus — exakt der Ablauf, mit dem site-1, site-2, site-3 und die Fight-Academy-Seite gebaut wurden.

## Voraussetzung

Dieser Skill braucht die Infrastruktur des Projektordners, in dem er liegt (relativ zum Skill: `../../../scripts/`,
`../../../.env` — also die Ordner `scripts/` und die Datei `.env` im Wurzelverzeichnis dieses Projekts):
`scripts/higgsfield.sh`, `scripts/screenshot.mjs`, `scripts/deploy.sh`, `scripts/setup-check.sh`, `.env` (OpenAI/Higgsfield-Keys), Netlify-CLI-Login.

### Schritt 0 — Setup prüfen (immer zuerst)

Vor JEDEM Durchlauf: `./scripts/setup-check.sh` im Projekt-Wurzelverzeichnis ausführen.
- Wenn das Skript mit Exit-Code 0 durchläuft ("Alles bereit"): weiter mit Schritt 1.
- Wenn `.env` fehlt oder Keys leer sind: dem Nutzer die fehlenden Punkte 1:1 aus der Skript-Ausgabe zeigen und auf `SETUP.md` im Projektordner verweisen (`cp .env.example .env`, dann Keys eintragen). NICHT versuchen, Keys zu erraten oder das Projekt trotzdem zu bauen — ohne Keys schlägt der Agent später mitten im Durchlauf fehl, das ist teurer als jetzt kurz zu stoppen.
- Wenn Netlify nicht eingeloggt ist: dem Nutzer sagen, dass er `netlify login` einmalig ausführen muss (öffnet den Browser), dann selbst nicht weitermachen bis das erledigt ist.

## Input

Der Text nach `/webseite-bauen` bzw. `#Webseite` ist der Auftrag — z.B. "eine Seite über Kaffeeröstung" (frei) oder "für https://www.irgendeine-firma.de, ein Rechtsanwalt in München" (echtes Unternehmen). Falls kein Text mitgegeben wurde: eine kurze Rückfrage stellen, worum es gehen soll.

## Ablauf

### 1. Slug festlegen

Kurzer kebab-case-Name aus dem Auftrag ableiten (z.B. "Fight Academy Leonberg" → `fight-academy`). Zielordner: `site-<slug>/` im Projektordner. Falls der Ordner schon existiert: nachfragen ob überschreiben/neu iterieren oder anderer Slug.

### 2. Freies Projekt vs. echtes Unternehmen erkennen

- **Enthält der Auftrag eine URL, einen konkreten Firmennamen oder "für [Unternehmen X]"** → echtes Unternehmen, weiter mit Schritt 3 (Recherche).
- **Sonst** (abstraktes Thema, Kunstidee, "irgendwas Krasses über Y") → keine Recherche nötig, direkt zu Schritt 4 mit voller kreativer Freiheit.

### 3. Recherche bei echtem Unternehmen (PFLICHT, nicht überspringen)

Vor dem Bauen recherchieren (WebFetch/`ctx_fetch_and_index` auf die genannte URL, sonst WebSearch nach dem Firmennamen):
- Exakter Name, Positionierung/Tonalität, Angebot/Leistungen
- Adresse, Telefon, E-Mail
- Logo (Favicon/Header-Bild) und dominante Markenfarben — wenn nicht zuverlässig auffindbar: eigenes, markenpassendes Wort-/Monogramm-Logo bauen statt zu raten
- Was NICHT bekannt ist (Preise, Trainer-/Mitarbeiternamen, Testimonials, genaue Zeiten) klar vermerken

**Nicht erfinden:** Für alles, was nicht recherchiert werden konnte, ehrliche Platzhalter-Formulierungen nutzen ("Preise auf Anfrage") statt konkrete falsche Fakten zu erfinden.

### 4. Agent dispatchen

Einen `Agent`-Tool-Aufruf mit `model: fable`, `subagent_type: general-purpose` starten (bei explizitem Wunsch nach mehreren Varianten: mehrere Aufrufe in einer Nachricht, gleiches Muster, verschiedene `site-<slug>-N/`-Ordner). Der Prompt muss enthalten:

- Zielpfad `site-<slug>/index.html`, Arbeitsverzeichnis = das Projekt-Wurzelverzeichnis (dort wo `scripts/` und `.env` liegen — den absoluten Pfad davon im Dispatch-Prompt mitgeben, nicht raten oder fest verdrahten)
- Bei echtem Unternehmen: alle recherchierten Fakten wörtlich mitgeben + explizites Fakten-nicht-erfinden-Gebot + Hinweis, ob es eine seriöse Business-Seite (klar lesbare Kernbotschaft, CTA, Kontakt) oder ein freies Kunstprojekt wird
- Bei freiem Projekt: volle kreative Freiheit, keine Themenvorgabe außer dem Auftrag
- `.env` laden: `set -a; source .env; set +a`
- Werkzeuge: `source scripts/higgsfield.sh && hf_image "<prompt>" "<ratio>"` / `hf_video "<bild-url>" "<prompt>" <sekunden>` — bei `not_enough_credits`-Fehler sofort auf verifizierte Stockfotos (Unsplash/Pexels) ausweichen, nicht wiederholen
- Screenshot-Check: `node scripts/screenshot.mjs site-<slug>/index.html /tmp/site-<slug>-pass{N}.png`, danach PNG mit Read-Tool ansehen
- Deploy erst nach sauberem letzten Check: `./scripts/deploy.sh site-<slug>`
- **PFLICHT: mindestens 3 Durchgänge** (Grundgerüst+Fehler beheben → Komplexität/Qualität erhöhen mit echten Bildern/Videos → Politur/Feinschliff), jeweils mit Screenshot-Check dazwischen
- Komplett autonom bis zum Deploy, keine Rückfragen zwischendurch
- Abschlussbericht-Format: Live-URL, 1-Satz-Konzept, genutzte Techniken/Werkzeuge (+ bei echtem Unternehmen: ob echtes Logo/echte Farben gefunden wurden)

### 5. Ergebnis melden

Nach Rückkehr des Agents: Live-URL + 1-2 Sätze Konzept direkt im Chat, keine Romane. Bei mehreren Varianten: kurze Liste.

## Bei Session-Limit-Unterbrechung

Falls ein Dispatch mit "session limit" fehlschlägt: nicht neu von vorne bauen. Per `SendMessage` an dieselbe `agentId` (falls Transkript vorhanden) fortsetzen lassen — Fortschritt in `site-<slug>/index.html` bleibt erhalten. Ohne Transkript: neu dispatchen, aber Prompt um den Hinweis ergänzen, zuerst die bestehende `index.html` zu lesen und darauf aufzubauen statt neu zu beginnen.
