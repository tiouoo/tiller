#!/usr/bin/env bash
set -euo pipefail

token="${CNB_TOKEN:-}"
[ -n "$token" ] || { echo "[cnb] token is empty; skipping tag push"; exit 0; }
repo="${CNB_REPO:?repository is required}"
tag="${CNB_TAG:?tag is required}"
commit="${CNB_COMMIT:-$(git rev-parse HEAD)}"
url="${CNB_GIT_URL:-https://cnb.cool/${repo}.git}"
host="$(printf '%s' "$url" | sed -E 's#^[a-z]+://([^/]+)/.*#\1#')"
auth="$(printf 'cnb:%s' "$token" | base64 | tr -d '\n')"

git tag -f "$tag" "$commit" >/dev/null
if ! output="$(GIT_TERMINAL_PROMPT=0 git -c "http.extraHeader=Authorization: Basic ${auth}" push --force "$url" "refs/tags/${tag}" 2>&1)"; then
  output="$(GIT_TERMINAL_PROMPT=0 git push --force "https://cnb:${token}@${host}/${repo}.git" "refs/tags/${tag}" 2>&1)" || {
    echo "[cnb] tag push failed: ${output//$token/***}" >&2
    exit 1
  }
fi
echo "[cnb] pushed ${tag}"
