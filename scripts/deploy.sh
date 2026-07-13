#!/usr/bin/env bash
set -euo pipefail
DIR="$1"
if [ ! -f "$DIR/index.html" ]; then
  echo "Fehler: $DIR/index.html existiert nicht" >&2
  exit 1
fi
OUTPUT=$(netlify deploy --dir="$DIR" --prod --json)
echo "$OUTPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).deploy_url || JSON.parse(d).url))"
