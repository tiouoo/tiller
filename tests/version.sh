#!/usr/bin/env bash
set -euo pipefail
script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/version.sh"

check() {
  local tag="$1" expected="$2" requested="${3:-}" repo out actual
  repo="$(mktemp -d)"
  git -C "$repo" init -q
  git -C "$repo" config user.name test
  git -C "$repo" config user.email test@example.com
  git -C "$repo" commit --allow-empty -qm init
  [ -z "$tag" ] || git -C "$repo" tag "$tag"
  out="$repo/output"
  (cd "$repo" && GITHUB_OUTPUT="$out" TILLER_VERSION="$requested" TILLER_NAME_PREFIX=v bash "$script")
  actual="$(sed -n 's/^version=//p' "$out")"
  [ "$actual" = "$expected" ] || { echo "expected $expected, got $actual" >&2; exit 1; }
  rm -rf "$repo"
}

check "" 1.0.0
check v1.0.0 1.0.1
check v1.0.8 1.0.9
check v1.0.9 1.1.0
check v1.9.9 1.10.0
check v1.10.9 1.11.0
check v2.0.0 2.0.1
check v1.0.0 2.0.0 2.0.0
echo "version tests passed"
