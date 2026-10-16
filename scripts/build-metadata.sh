#!/usr/bin/env bash
set -euo pipefail

kind="${TILLER_BUILD_KIND:?build kind is required}"
base_file="${TILLER_BASE_VERSION_FILE:?base version file is required}"
epoch="${TILLER_BUILD_EPOCH:?build epoch is required}"
base_version="$(tr -d '[:space:]' < "$base_file")"
start_epoch="$(TZ='Asia/Shanghai' date -d "$epoch" +%s)"
now_epoch="$(date +%s)"
total_minutes=$(( (now_epoch - start_epoch) / 60 ))
if [ "$total_minutes" -lt 0 ]; then
  echo "Tiller: build epoch is in the future" >&2
  exit 1
fi
days=$((total_minutes / 1440))
hours=$(((total_minutes % 1440) / 60))
minutes=$((total_minutes % 60))
app_version="0.${days}.${hours}.${minutes}"
commit="$(git rev-parse --short=6 HEAD)"
build_time="$(TZ='Asia/Shanghai' date -Iseconds)"
timestamp="$(TZ='Asia/Shanghai' date +'%Y%m%d%H%M')"
title="build-${kind}-${app_version}-${TILLER_RUN_ID:-}-${commit}"
json="$(python3 - "$kind" "$build_time" "${TILLER_RUN_ID:-}" "$commit" "$base_version" "$timestamp" "$title" <<'PY'
import json, sys
print(json.dumps({
    "type": sys.argv[1],
    "build-time": sys.argv[2],
    "action": sys.argv[3],
    "commit": sys.argv[4],
    "version": sys.argv[5],
    "timestamp": sys.argv[6],
    "version_title": sys.argv[7],
}, ensure_ascii=False, separators=(",", ":")))
PY
)"
{
  echo "json=${json}"
  echo "app_version=${app_version}"
  echo "commit=${commit}"
  echo "timestamp=${timestamp}"
  echo "title=${title}"
} >> "${GITHUB_OUTPUT:-/dev/stdout}"
