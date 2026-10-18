#!/usr/bin/env bash
set -euo pipefail

output="${TILLER_CHANGELOG_OUTPUT:-RELEASE_CHANGELOG.md}"
repo_url="${TILLER_REPO_URL:-}"
sha="${TILLER_SHA:-HEAD}"
head="$(git rev-parse --verify "${TILLER_HEAD_REF:-HEAD}^{commit}")"
stable_tag="${TILLER_BASE_REF:-auto}"
if [ "$stable_tag" = auto ]; then
  stable_tag="$(git tag -l --sort=-v:refname 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 || true)"
fi
[ "$stable_tag" != none ] || stable_tag=''
tmp="${output}.tmp"
trap 'rm -f "$tmp"' EXIT
args=()

if [ -n "$stable_tag" ]; then
  base="$(git rev-parse --verify "${stable_tag}^{commit}")"
  args+=("${base}..${head}")
  heading="Changes since \`${stable_tag}\`:"
else
  case "${TILLER_INITIAL_HISTORY:-recent}" in
    recent) args+=(-20) ;;
    all) ;;
    *) echo 'Tiller: initial-history must be recent or all' >&2; exit 1 ;;
  esac
  args+=("$head")
  heading="Recent commits:"
fi

{
  echo "$heading"
  echo
  git log --no-merges --pretty=tformat:"- %s ([%h](${repo_url}/commit/%H))" "${args[@]}"
} > "$tmp"

if [ "$(grep -c '^- ' "$tmp" || true)" -eq 0 ]; then
  printf '%s\n' "${TILLER_EMPTY_MESSAGE:-No changes since the previous stable release.}" > "$tmp"
elif [ -n "$stable_tag" ] && [ -n "$repo_url" ]; then
  { echo; echo "**Full comparison**: ${repo_url}/compare/${stable_tag}...${sha}"; } >> "$tmp"
fi
mv "$tmp" "$output"
cat "$output"
