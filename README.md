# Wild Websites

Autonomer Website-Builder nach dem Vorbild von Nick Saraevs "Fable 5"-Video:
ein KI-Agent (Claude, Modell "Fable") baut mit echter Bild-/Videogenerierung,
Selbst-Verifikation per Screenshot und automatischem Live-Deploy technisch
und visuell extreme Websites — ganz ohne dass du selbst Design-Entscheidungen
triffst.

Funktioniert für zwei Arten von Aufträgen:
- **Freie Kunst-/Technik-Demos** ("bau mir eine krasse Seite über X")
- **Echte Business-Websites** (recherchiert vorher echte Fakten, Logo und
  Markenfarben der Firma — erfindet keine Preise, Namen oder Testimonials)

## Schnellstart

1. Voraussetzungen installieren (siehe [SETUP.md](SETUP.md))
2. `cp .env.example .env` und deine eigenen API-Keys eintragen
3. `./scripts/setup-check.sh` — prüft ob alles bereit ist
4. In Claude Code in diesem Ordner: `/webseite-bauen <was du willst>`

Das war's — nach ein paar Minuten liegt eine fertige, live deployte Website
als `site-<name>/index.html` im Projektordner, plus die Netlify-URL im Chat.

## Wie es funktioniert

Der Skill `.claude/skills/webseite-bauen/` orchestriert einen einzelnen
autonomen Agenten-Durchlauf:

1. Grundgerüst bauen, Screenshot-Check, offensichtliche Fehler beheben
2. Design-Komplexität erhöhen, echte generierte Bilder/Videos statt
   Platzhalter, Screenshot-Check
3. Politur/Feinschliff, letzter Screenshot-Check
4. Erst wenn alles sauber ist: automatischer Deploy auf Netlify

Details: [docs/superpowers/specs/2026-07-13-wild-websites-design.md](docs/superpowers/specs/2026-07-13-wild-websites-design.md)
und [docs/superpowers/plans/2026-07-13-wild-websites-plan.md](docs/superpowers/plans/2026-07-13-wild-websites-plan.md).

## Kosten

Jeder Website-Durchlauf verursacht echte Kosten: Claude-Nutzung, OpenAI-
Bildgenerierung, Higgsfield-Bild-/Videogenerierung (falls Guthaben
vorhanden), Netlify-Hosting (kostenloser Tarif reicht für den Start).
Higgsfield ohne Guthaben führt nicht zum Abbruch — der Agent weicht dann
automatisch auf kostenlose Stockfotos aus.
