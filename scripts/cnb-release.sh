#!/usr/bin/env bash
set -euo pipefail

token="${CNB_TOKEN:-}"
[ -n "$token" ] || { echo "[cnb] token is empty; skipping release"; exit 0; }
repo="${CNB_REPO:?repository is required}"
tag="${CNB_TAG:?tag is required}"
name="${CNB_NAME:-$tag}"
api="${CNB_API:-https://api.cnb.cool}"
accept='application/vnd.cnb.api+json'

request() {
  local method="$1" path="$2" body="${3:-}"
  local -a args=(-g -sS -X "$method" -H "Authorization: Bearer ${token}" -H "Accept: ${accept}")
  [ -z "$body" ] || args+=(-H 'Content-Type: application/json' --data "$body")
  case "$path" in http://*|https://*) ;; *) path="${api}${path}" ;; esac
  curl "${args[@]}" "$path"
}

body=''
[ -z "${CNB_BODY_FILE:-}" ] || [ ! -f "$CNB_BODY_FILE" ] || body="$(<"$CNB_BODY_FILE")"
pre=false; [ "${CNB_PRERELEASE:-false}" != true ] || pre=true
payload="$(jq -n --arg tag "$tag" --arg name "$name" --arg body "$body" --argjson pre "$pre" --arg latest "${CNB_MAKE_LATEST:-false}" '{tag_name:$tag,name:$name,body:$body,prerelease:$pre,make_latest:$latest}')"
old="$(request GET "/${repo}/-/releases/tags/${tag}" 2>/dev/null | jq -r '.id // empty' 2>/dev/null || true)"
[ -z "$old" ] || request DELETE "/${repo}/-/releases/${old}" >/dev/null 2>&1 || true
response="$(request POST "/${repo}/-/releases" "$payload")"
release="$(jq -r '.id // empty' <<<"$response")"
[ -n "$release" ] || { echo "[cnb] release creation failed: $response" >&2; exit 1; }

upload() {
  local file="$1" size metadata response upload_url verify_url
  size="$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")"
  metadata="$(jq -n --arg name "$(basename "$file")" --argjson size "$size" '{asset_name:$name,size:$size,overwrite:true}')"
  response="$(request POST "/${repo}/-/releases/${release}/asset-upload-url" "$metadata")"
  upload_url="$(jq -r '.upload_url // empty' <<<"$response")"; verify_url="$(jq -r '.verify_url // empty' <<<"$response")"
  [ -n "$upload_url" ] && [ -n "$verify_url" ] || { echo '[cnb] asset URL request failed' >&2; exit 1; }
  curl -gfsS -X PUT --retry 3 --retry-all-errors --data-binary "@$file" "$upload_url" >/dev/null
  request POST "$verify_url" '{}' >/dev/null
}

while IFS= read -r pattern; do
  [ -n "$pattern" ] || continue
  while IFS= read -r file; do upload "$file"; done < <(compgen -G "$pattern" || true)
done <<< "${CNB_FILES:-}"
echo "[cnb] release ${tag} synchronized"
