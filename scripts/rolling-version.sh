#!/usr/bin/env bash
set -euo pipefail

start_epoch="$(TZ='Asia/Shanghai' date -d "${TILLER_EPOCH:?epoch is required}" +%s)"
now_epoch="${TILLER_NOW_EPOCH:-$(date +%s)}"
total_minutes=$(( (now_epoch - start_epoch) / 60 ))
if [ "$total_minutes" -lt 0 ]; then
  echo "Tiller: epoch is in the future" >&2
  exit 1
fi
days=$((total_minutes / 1440))
hours=$(((total_minutes % 1440) / 60))
minutes=$((total_minutes % 60))
echo "version=0.${days}.${hours}.${minutes}" >> "${GITHUB_OUTPUT:-/dev/stdout}"
