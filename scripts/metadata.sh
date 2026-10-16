#!/usr/bin/env bash
set -euo pipefail

build_time="$(TZ='Asia/Shanghai' date -Iseconds)"
release_date="$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')"
json="$(node -e 'const [type,time,action,commit,version,timestamp,title]=process.argv.slice(1); const value={type,"build-time":time,action,commit,version,version_title:title}; if(timestamp)value.timestamp=timestamp; process.stdout.write(JSON.stringify(value))' \
  "${TILLER_TYPE:?type is required}" "$build_time" "${TILLER_RUN_ID:-}" \
  "${TILLER_COMMIT:?commit is required}" "${TILLER_VERSION:?version is required}" \
  "${TILLER_TIMESTAMP:-}" "${TILLER_TITLE:?title is required}")"

{
  echo "json=${json}"
  echo "build_time=${build_time}"
  echo "release_date=${release_date}"
} >> "${GITHUB_OUTPUT:-/dev/stdout}"
