#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
epoch="$(TZ='Asia/Shanghai' date -d '2026-07-10 00:00:00' +%s)"
now=$((epoch + 10 * 1440 * 60 + 3 * 60 * 60 + 7 * 60))
output="$(mktemp)"
GITHUB_OUTPUT="$output" TILLER_EPOCH='2026-07-10 00:00:00' TILLER_NOW_EPOCH="$now" bash "$root/scripts/rolling-version.sh"
grep -qx 'version=0.10.3.7' "$output"
rm -f "$output"
echo 'rolling version tests passed'
