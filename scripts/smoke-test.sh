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
netlify status || true

echo "== Playwright =="
npx --yes playwright --version
