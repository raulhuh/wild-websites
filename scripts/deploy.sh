#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ] || [ -z "${1:-}" ]; then
  echo "Fehler: Nutzung: $0 <verzeichnis>" >&2
  exit 1
fi

DIR="$1"

if [ ! -f "$DIR/index.html" ]; then
  echo "Fehler: $DIR/index.html existiert nicht" >&2
  exit 1
fi

# Jeder Ordner bekommt eine eigene, isolierte Netlify-Site (Name aus dem
# Ordnernamen abgeleitet), damit mehrere Aufrufe von deploy.sh (z.B. für
# site-1, site-2, site-3) niemals dieselbe Site überschreiben. Ein "nacktes"
# `netlify deploy` würde über .netlify/state.json + netlify.toml im
# Projekt-Root auto-linken und so jeden Ordner auf dieselbe Site deployen.
SITE_NAME="wild-websites-$(basename "$DIR")"

# Existierende Site mit diesem Namen suchen, damit wiederholte Deploys
# desselben Ordners dieselbe Site treffen statt Duplikate anzulegen.
SITES_JSON=$(netlify sites:list --json) || {
  echo "Fehler: 'netlify sites:list' fehlgeschlagen" >&2
  exit 1
}
SITE_ID=$(echo "$SITES_JSON" | node -e "
let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
  try {
    const sites = JSON.parse(d);
    const match = sites.find(s => s.name === process.argv[1]);
    console.log(match ? match.id : '');
  } catch (e) { process.exit(1) }
})" "$SITE_NAME") || {
  echo "Fehler: Konnte Antwort von 'netlify sites:list' nicht parsen" >&2
  exit 1
}

if [ -z "$SITE_ID" ]; then
  CREATE_JSON=$(netlify sites:create --name "$SITE_NAME" --disable-linking --json) || {
    echo "Fehler: 'netlify sites:create' fehlgeschlagen für Site '$SITE_NAME'" >&2
    exit 1
  }
  SITE_ID=$(echo "$CREATE_JSON" | node -e "
let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
  try {
    const v = JSON.parse(d).id;
    if (v === undefined || v === null) throw new Error('missing field');
    console.log(v);
  } catch (e) { process.exit(1) }
})") || {
    echo "Fehler: Konnte Antwort von 'netlify sites:create' nicht parsen: $CREATE_JSON" >&2
    exit 1
  }
fi

OUTPUT=$(netlify deploy --dir="$DIR" --prod --json --site="$SITE_ID") || {
  echo "Fehler: 'netlify deploy' fehlgeschlagen für Ordner '$DIR' (Site: $SITE_NAME)" >&2
  exit 1
}

if [ -z "$OUTPUT" ]; then
  echo "Fehler: 'netlify deploy' lieferte keine Ausgabe für Ordner '$DIR'" >&2
  exit 1
fi

echo "$OUTPUT" | node -e "
let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
  try {
    const parsed = JSON.parse(d);
    const v = parsed.deploy_url || parsed.url;
    if (v === undefined || v === null) throw new Error('missing field');
    console.log(v);
  } catch (e) { process.exit(1) }
})" || {
  echo "Fehler: Konnte Deploy-Ausgabe nicht parsen (deploy_url/url fehlt): $OUTPUT" >&2
  exit 1
}
