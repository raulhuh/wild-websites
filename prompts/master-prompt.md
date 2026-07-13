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
