#!/usr/bin/env bash
set -euo pipefail

token="${GITCODE_TOKEN:-}"
[ -n "$token" ] || { echo "[gitcode] token is empty; skipping tag push"; exit 0; }
repo="${GITCODE_REPO:?repository is required}"
tag="${GITCODE_TAG:?tag is required}"
commit="${GITCODE_COMMIT:-$(git rev-parse HEAD)}"
url="${GITCODE_GIT_URL:-https://gitcode.com/${repo}.git}"
host="$(printf '%s' "$url" | sed -E 's#^[a-z]+://([^/]+)/.*#\1#')"
user="${GITCODE_GIT_USER:-oauth2}"
auth="$(printf '%s:%s' "$user" "$token" | base64 | tr -d '\n')"

git tag -f "$tag" "$commit" >/dev/null
if ! output="$(GIT_TERMINAL_PROMPT=0 git -c "http.extraHeader=Authorization: Basic ${auth}" push --force "$url" "refs/tags/${tag}" 2>&1)"; then
  output="$(GIT_TERMINAL_PROMPT=0 git push --force "https://${user}:${token}@${host}/${repo}.git" "refs/tags/${tag}" 2>&1)" || {
    echo "[gitcode] tag push failed: ${output//$token/***}" >&2
    exit 1
  }
fi
echo "[gitcode] pushed ${tag}"
