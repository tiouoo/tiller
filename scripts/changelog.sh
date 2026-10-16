#!/usr/bin/env bash
set -euo pipefail

output="${TILLER_CHANGELOG_OUTPUT:-RELEASE_CHANGELOG.md}"
repo_url="${TILLER_REPO_URL:-}"
sha="${TILLER_SHA:-HEAD}"
stable_tag="$(git tag -l --sort=-v:refname 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 || true)"
tmp="${output}.tmp"

if [ -n "$stable_tag" ]; then
  range="${stable_tag}..HEAD"
  heading="Changes since \`${stable_tag}\`:"
else
  range="-20"
  heading="Recent commits:"
fi

{
  echo "$heading"
  echo
  git log --no-merges --pretty=tformat:"- %s ([%h](${repo_url}/commit/%H))" "$range" || true
} > "$tmp"

if [ "$(grep -c '^- ' "$tmp" || true)" -eq 0 ]; then
  printf '%s\n' "${TILLER_EMPTY_MESSAGE:-No changes since the previous stable release.}" > "$tmp"
elif [ -n "$stable_tag" ] && [ -n "$repo_url" ]; then
  { echo; echo "**Full comparison**: ${repo_url}/compare/${stable_tag}...${sha}"; } >> "$tmp"
fi
mv "$tmp" "$output"
cat "$output"
