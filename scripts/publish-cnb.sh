#!/usr/bin/env bash
set -euo pipefail

api="${CNB_API:-https://api.cnb.cool}"
web="${CNB_WEB:-https://cnb.cool}"
repo="${CNB_REPO:?CNB_REPO is required}"
tag="${CNB_TAG:?CNB_TAG is required}"
token="${CNB_TOKEN:-}"
git_url="${CNB_GIT_URL:-${web}/${repo}.git}"
accept="application/vnd.cnb.api+json"

if [ -z "$token" ]; then
  echo "[cnb] token is empty; skipping synchronization"
  exit 0
fi

name="${CNB_NAME:-$tag}"

cnb_request() {
  local method="$1" path="$2" body="${3:-}"
  local -a args=(-g -sS -X "$method" -H "Authorization: Bearer ${token}" -H "Accept: ${accept}")
  [ -z "$body" ] || args+=(-H 'Content-Type: application/json' --data "$body")
  case "$path" in http://*|https://*) ;; *) path="${api}${path}" ;; esac
  curl "${args[@]}" "$path"
}

push_tag() {
  local commit auth host output
  commit="${CNB_COMMIT:-$(git rev-parse HEAD)}"
  git tag -f "$tag" "$commit" >/dev/null
  auth="$(printf 'cnb:%s' "$token" | base64 | tr -d '\n')"
  host="$(printf '%s' "$git_url" | sed -E 's#^[a-z]+://([^/]+)/.*#\1#')"
  if ! output="$(GIT_TERMINAL_PROMPT=0 git -c "http.extraHeader=Authorization: Basic ${auth}" push --force "$git_url" "refs/tags/${tag}" 2>&1)"; then
    output="$(GIT_TERMINAL_PROMPT=0 git push --force "https://cnb:${token}@${host}/${repo}.git" "refs/tags/${tag}" 2>&1)" || {
      echo "[cnb] tag push failed: ${output//$token/***}" >&2
      return 1
    }
  fi
}

release_id() {
  cnb_request GET "/${repo}/-/releases/tags/${tag}" 2>/dev/null | jq -r '.id // empty' 2>/dev/null || true
}

release_json() {
  local body="" pre=false
  [ -z "${CNB_BODY_FILE:-}" ] || [ ! -f "$CNB_BODY_FILE" ] || body="$(<"$CNB_BODY_FILE")"
  [ "${CNB_PRERELEASE:-false}" != true ] || pre=true
  jq -n --arg tag "$tag" --arg name "$name" --arg body "$body" --argjson pre "$pre" \
    --arg latest "${CNB_MAKE_LATEST:-false}" --arg target "${CNB_COMMIT:-}" \
    '{tag_name:$tag,name:$name,body:$body,prerelease:$pre,make_latest:$latest}
     + (if $target == "" then {} else {target_commitish:$target} end)'
}

upload_asset() {
  local release="$1" file="$2" size metadata response upload verify
  [ -f "$file" ] || { echo "[cnb] asset not found: $file" >&2; return 1; }
  size="$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")"
  metadata="$(jq -n --arg name "$(basename "$file")" --argjson size "$size" '{asset_name:$name,size:$size,overwrite:true}')"
  response="$(cnb_request POST "/${repo}/-/releases/${release}/asset-upload-url" "$metadata")"
  upload="$(jq -r '.upload_url // empty' <<<"$response")"
  verify="$(jq -r '.verify_url // empty' <<<"$response")"
  [ -n "$upload" ] && [ -n "$verify" ] || { echo "[cnb] could not obtain an asset upload URL" >&2; return 1; }
  curl -gfsS -X PUT --connect-timeout 10 --max-time "${CNB_UPLOAD_MAX_TIME:-3600}" \
    --retry 3 --retry-delay 2 --retry-connrefused --retry-all-errors --data-binary "@${file}" "$upload" >/dev/null
  cnb_request POST "$verify" '{}' >/dev/null
  echo "[cnb] uploaded $(basename "$file")"
}

echo "[cnb] synchronizing ${tag} to ${repo}"
push_tag
old="$(release_id)"
if [ -n "$old" ]; then
  cnb_request DELETE "/${repo}/-/releases/${old}" >/dev/null 2>&1 || true
fi
response="$(cnb_request POST "/${repo}/-/releases" "$(release_json)")"
release="$(jq -r '.id // empty' <<<"$response")"
[ -n "$release" ] || { echo "[cnb] release creation failed: $response" >&2; exit 1; }
if [ -n "${CNB_FILES:-}" ]; then
  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    matched=false
    while IFS= read -r file; do
      matched=true
      upload_asset "$release" "$file"
    done < <(compgen -G "$pattern" || true)
    $matched || echo "[cnb] no assets matched: $pattern" >&2
  done <<< "$CNB_FILES"
fi
echo "[cnb] synchronization complete"
