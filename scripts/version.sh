#!/usr/bin/env bash
set -euo pipefail

output_file="${GITHUB_OUTPUT:-/dev/stdout}"
requested="${TILLER_VERSION:-}"
minor_limit="${TILLER_MINOR_LIMIT:-0}"
[[ "$minor_limit" =~ ^(0|[1-9][0-9]*)$ ]] || { echo 'Tiller: minor-limit must be a nonnegative integer' >&2; exit 1; }
previous_tag="$(git tag -l --sort=-v:refname 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 || true)"

if [ -n "$requested" ]; then
  version="${requested#v}"
elif [ -n "$previous_tag" ]; then
  base="${previous_tag#v}"
  IFS=. read -r major minor patch <<< "$base"
  if [ "$patch" -ge 9 ]; then
    patch=0
    minor=$((minor + 1))
  else
    patch=$((patch + 1))
  fi
  if [ "$minor_limit" -gt 0 ] && [ "$minor" -gt "$minor_limit" ]; then
    minor=0
    major=$((major + 1))
  fi
  version="${major}.${minor}.${patch}"
else
  version="1.0.0"
fi

if ! [[ "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "Tiller: version must use X.Y.Z, for example 2.0.0" >&2
  exit 1
fi

IFS=. read -r _ _ patch <<< "$version"
if [ "$patch" -gt 9 ]; then
  echo "Tiller: patch must be between 0 and 9" >&2
  exit 1
fi

tag="v${version}"
if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null; then
  echo "Tiller: tag ${tag} already exists" >&2
  exit 1
fi

{
  echo "version=${version}"
  echo "tag=${tag}"
  echo "previous_tag=${previous_tag}"
} >> "$output_file"
