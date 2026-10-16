#!/usr/bin/env bash
set -euo pipefail

output_file="${GITHUB_OUTPUT:-/dev/stdout}"
requested="${TILLER_VERSION:-}"
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
  version="${major}.${minor}.${patch}"
else
  version="1.0.0"
fi

if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Tiller: version must use X.Y.Z, for example 2.0.0" >&2
  exit 1
fi

IFS=. read -r major minor patch <<< "$version"
if [ "$patch" -gt 9 ]; then
  echo "Tiller: patch must be between 0 and 9" >&2
  exit 1
fi

tag="v${version}"
if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null; then
  echo "Tiller: tag ${tag} already exists" >&2
  exit 1
fi

commit="$(git rev-parse --short=7 HEAD)"
build_time="$(TZ='Asia/Shanghai' date -Iseconds)"
release_date="$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')"
release_name="${TILLER_NAME_PREFIX:-v}${version}"
run_id="${TILLER_RUN_ID:-}"

json="$(python3 - "$build_time" "$run_id" "$commit" "$version" "$release_name" <<'PY'
import json, sys
print(json.dumps({
    "type": "release",
    "build-time": sys.argv[1],
    "action": sys.argv[2],
    "commit": sys.argv[3],
    "version": sys.argv[4],
    "version_title": sys.argv[5],
}, ensure_ascii=False, separators=(",", ":")))
PY
)"

{
  echo "version=${version}"
  echo "tag=${tag}"
  echo "previous_tag=${previous_tag}"
  echo "commit=${commit}"
  echo "build_time=${build_time}"
  echo "release_date=${release_date}"
  echo "release_name=${release_name}"
  echo "json=${json}"
} >> "$output_file"
