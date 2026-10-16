#!/usr/bin/env bash
set -euo pipefail

api="${GITCODE_API:-https://gitcode.com/api/v5}"
web="${GITCODE_WEB:-https://gitcode.com}"
repo="${GITCODE_REPO:?GITCODE_REPO is required}"
tag="${GITCODE_TAG:?GITCODE_TAG is required}"
token="${GITCODE_TOKEN:-}"
git_url="${GITCODE_GIT_URL:-${web}/${repo}.git}"

if [ -z "$token" ]; then
  echo "[gitcode] token is empty; skipping synchronization"
  exit 0
fi

name="${GITCODE_NAME:-$tag}"
prerelease="${GITCODE_PRERELEASE:-false}"
releases="${api}/repos/${repo}/releases"

release_exists() {
  curl -gfsS -H "Authorization: Bearer ${token}" "${releases}/tags/${tag}" 2>/dev/null \
    | jq -e --arg tag "$tag" '.tag_name == $tag' >/dev/null 2>&1
}

push_tag() {
  local commit auth host output
  commit="${GITCODE_COMMIT:-$(git rev-parse HEAD)}"
  git tag -f "$tag" "$commit" >/dev/null
  if [ "${GITCODE_SKIP_TAG_PUSH:-false}" = "true" ]; then
    echo "[gitcode] tag push skipped"
    return
  fi
  auth="$(printf '%s:%s' "${GITCODE_GIT_USER:-oauth2}" "$token" | base64 | tr -d '\n')"
  host="$(printf '%s' "$git_url" | sed -E 's#^[a-z]+://([^/]+)/.*#\1#')"
  if ! output="$(GIT_TERMINAL_PROMPT=0 git -c "http.extraHeader=Authorization: Basic ${auth}" push --force "$git_url" "refs/tags/${tag}" 2>&1)"; then
    output="$(GIT_TERMINAL_PROMPT=0 git push --force "https://${GITCODE_GIT_USER:-oauth2}:${token}@${host}/${repo}.git" "refs/tags/${tag}" 2>&1)" || {
      echo "[gitcode] tag push failed; continuing with release synchronization" >&2
      printf '%s\n' "${output//$token/***}" >&2
    }
  fi
}

release_request() {
  local method="$1" url="$2" response
  local -a args=(-g -sS -X "$method" -H "Authorization: Bearer ${token}"
    -H "Content-Type: application/x-www-form-urlencoded"
    --data-urlencode "access_token=${token}" --data-urlencode "tag_name=${tag}"
    --data-urlencode "name=${name}" --data-urlencode "prerelease=${prerelease}")
  if [ -n "${GITCODE_BODY_FILE:-}" ] && [ -f "$GITCODE_BODY_FILE" ]; then
    args+=(--data-urlencode "body@${GITCODE_BODY_FILE}")
  fi
  if [ "$method" = POST ] && [ -n "${GITCODE_COMMIT:-}" ] && [ "${GITCODE_SKIP_TAG_PUSH:-false}" != true ]; then
    args+=(--data-urlencode "target_commitish=${GITCODE_COMMIT}")
  fi
  response="$(curl "${args[@]}" "$url")"
  jq -e --arg tag "$tag" '.tag_name == $tag' >/dev/null 2>&1 <<<"$response" || {
    echo "[gitcode] release request failed: $response" >&2
    return 1
  }
}

echo "[gitcode] synchronizing ${tag} to ${repo}"
push_tag
if release_exists; then
  release_request PATCH "${releases}/${tag}"
else
  release_request POST "$releases"
fi
echo "[gitcode] synchronization complete"
