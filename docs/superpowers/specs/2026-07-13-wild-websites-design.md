# Wild Websites — Design

## Zweck

Sideprojekt, unabhängig von Haus-und-Höhe-Kundenarbeit. Ziel: die Architektur
aus Nick Saraevs Video ("Fable 5 Is Back. Use It To Print With These $10K
Websites") strukturell nachbauen — ein autonomer Multi-Website-Builder, der
technisch/handwerklich High-End-Ergebnisse produziert. Kein Marken- oder
Konversions-Constraint (anders als die Haus-und-Höhe-LP-Builder-Arbeit) —
volle kreative Freiheit für das Modell.

Der konkrete spätere Verwendungszweck (Templates verkaufen, Portfolio,
Social-Content) ist bewusst offen und beeinflusst dieses Design nicht.

## Architektur

Kein neues Softwareprodukt. Der Builder läuft direkt in einer Claude-Code-
Session: ein Master-Prompt pro Website + mehrere parallele Agenten (Claude
Code `Agent`-Tool, `subagent_type: general-purpose`, volle Tool-Rechte),
je einer pro Website, analog zu Nicks Subagent-Parallelisierung.

Jeder Website-Agent hat Zugriff auf:

- **Bildgenerierung:** OpenAI GPT-Image API (Key in `.env`, `OPENAI_API_KEY`)
- **Video/Animation:** Higsfield API (Keys in `.env`, `HIGSFIELD_API_ID` /
  `HIGSFIELD_API_SECRET`) — Request-Format wird zur Implementierungszeit live
  aus der Higsfield-API-Doku recherchiert, nicht vorab angenommen
- **Inspirationsbilder/Assets (Pinterest-Ersatz):** Unsplash/Pexels, kostenlos,
  kein Login nötig
- **Selbst-Verifikation:** Playwright (lokal über `npx playwright`, bereits
  verfügbar) rendert die generierte HTML-Datei und macht einen Screenshot;
  der Agent bewertet sein eigenes Ergebnis anhand des Screenshots (Vision)
  und korrigiert
- **Hosting:** Netlify CLI (`netlify deploy`), bereits unter
  raul@hausundhoehe.de eingeloggt auf diesem Rechner

## Ablauf pro Website (im Master-Prompt verankert)

1. Website-Konzept frei wählen (Agent hat volle kreative Freiheit, keine
   Themenvorgabe von außen nötig — analog zu Nicks Prompt: "total creative
   freedom")
2. Bauen als einzelne, selbst-enthaltene HTML-Datei (Three.js o.ä. bei Bedarf,
   eigene Fonts, Animationen)
3. Mindestens 3 Verbesserungs-Durchgänge PFLICHT, jeweils mit Playwright-
   Screenshot-Check dazwischen:
   - Pass 1: Grundgerüst + Screenshot-Check auf offensichtliche Fehler
     (Overflow, kaputte Bilder, unleserlicher Text)
   - Pass 2: Design-Komplexität/-Qualität erhöhen
   - Pass 3: Politur/Feinschliff
4. Deploy auf Netlify, Live-Link zurückmelden

## Umfang Pilot

3 Websites, parallel gebaut (3 Agent-Aufrufe in einer Nachricht).

## Output

- Ordner: `/Users/raulszekely/Desktop/Programme/wild-websites/`
- Unterordner je Website: `site-1/`, `site-2/`, `site-3/`
- Git-Repo lokal (dieses Projekt), `.env` ausgeschlossen von Git

## Explizit nicht Teil dieses Durchlaufs

- Öffentliche `/guide`-Route mit Anleitung (Nicks Community-Angebot)
- Social-Media-Content/Video über die Ergebnisse
- Skalierung auf 25 Websites (erst nach Pilot-Bewertung)

## Offene Punkte für Implementierung

- Higsfield-API-Request-Format vorab per Doku-Recherche klären (nicht
  angenommen, s.o.)
- Kosten pro Website nicht vorab geschätzt (Nick nannte ~$5-10/Website als
  Richtwert für Bild/Video-Generierung + Modell-Tokens) — nach Pilot prüfen
