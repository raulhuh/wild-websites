#!/usr/bin/env bash
# source this file: `source scripts/higgsfield.sh`
_hf_auth() { echo "Authorization: Key ${HIGSFIELD_API_ID}:${HIGSFIELD_API_SECRET}"; }

_hf_poll() {
  local status_url="$1"
  local result
  for i in $(seq 1 60); do
    result=$(curl -sS "$status_url" --header "$(_hf_auth)")
    local status
    status=$(echo "$result" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const v=JSON.parse(d).status;if(v===undefined||v===null)throw new Error('missing field');console.log(v)}catch(e){process.exit(1)}})") || { echo "Higgsfield: failed to parse status response: $result" >&2; return 1; }
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
  status_url=$(echo "$resp" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const v=JSON.parse(d).status_url;if(v===undefined||v===null)throw new Error('missing field');console.log(v)}catch(e){process.exit(1)}})") || { echo "Higgsfield: failed to parse status_url response: $resp" >&2; return 1; }
  local final
  final=$(_hf_poll "$status_url") || return 1
  echo "$final" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const v=JSON.parse(d).images[0].url;if(v===undefined||v===null)throw new Error('missing field');console.log(v)}catch(e){process.exit(1)}})" || { echo "Higgsfield: failed to parse image URL response" >&2; return 1; }
}

hf_video() {
  local image_url="$1" prompt="$2" duration="${3:-5}"
  local resp
  resp=$(curl -sS -X POST 'https://platform.higgsfield.ai/higgsfield-ai/dop/standard' \
    --header "$(_hf_auth)" --header 'Content-Type: application/json' \
    --data "$(node -e "console.log(JSON.stringify({image_url:process.argv[1],prompt:process.argv[2],duration:Number(process.argv[3])}))" "$image_url" "$prompt" "$duration")")
  local status_url
  status_url=$(echo "$resp" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const v=JSON.parse(d).status_url;if(v===undefined||v===null)throw new Error('missing field');console.log(v)}catch(e){process.exit(1)}})") || { echo "Higgsfield: failed to parse status_url response: $resp" >&2; return 1; }
  local final
  final=$(_hf_poll "$status_url") || return 1
  echo "$final" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const v=JSON.parse(d).video.url;if(v===undefined||v===null)throw new Error('missing field');console.log(v)}catch(e){process.exit(1)}})" || { echo "Higgsfield: failed to parse video URL response" >&2; return 1; }
}
