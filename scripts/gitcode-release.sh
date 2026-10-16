#!/usr/bin/env bash
set -euo pipefail

token="${GITCODE_TOKEN:-}"
[ -n "$token" ] || { echo "[gitcode] token is empty; skipping release"; exit 0; }
repo="${GITCODE_REPO:?repository is required}"
tag="${GITCODE_TAG:?tag is required}"
name="${GITCODE_NAME:-$tag}"
prerelease="${GITCODE_PRERELEASE:-false}"
releases="${GITCODE_API:-https://gitcode.com/api/v5}/repos/${repo}/releases"

exists() {
  curl -gfsS -H "Authorization: Bearer ${token}" "${releases}/tags/${tag}" 2>/dev/null \
    | jq -e --arg tag "$tag" '.tag_name == $tag' >/dev/null 2>&1
}

request() {
  local method="$1" url="$2" response
  local -a args=(-g -sS -X "$method" -H "Authorization: Bearer ${token}"
    -H 'Content-Type: application/x-www-form-urlencoded'
    --data-urlencode "access_token=${token}" --data-urlencode "tag_name=${tag}"
    --data-urlencode "name=${name}" --data-urlencode "prerelease=${prerelease}")
  if [ -n "${GITCODE_BODY_FILE:-}" ] && [ -f "$GITCODE_BODY_FILE" ]; then
    args+=(--data-urlencode "body@${GITCODE_BODY_FILE}")
  fi
  response="$(curl "${args[@]}" "$url")"
  jq -e --arg tag "$tag" '.tag_name == $tag' >/dev/null 2>&1 <<<"$response" || {
    echo "[gitcode] release request failed: $response" >&2
    exit 1
  }
}

if exists; then request PATCH "${releases}/${tag}"; else request POST "$releases"; fi
echo "[gitcode] release ${tag} synchronized"
