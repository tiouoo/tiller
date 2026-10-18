#!/usr/bin/env bash
set -euo pipefail
script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/version.sh"

check() {
  local tag="$1" expected="$2" requested="${3:-}" limit="${4:-0}" repo out actual
  repo="$(mktemp -d)"
  git -C "$repo" init -q
  git -C "$repo" config user.name test
  git -C "$repo" config user.email test@example.com
  git -C "$repo" commit --allow-empty -qm init
  [ -z "$tag" ] || git -C "$repo" tag "$tag"
  out="$repo/output"
  (cd "$repo" && GITHUB_OUTPUT="$out" TILLER_VERSION="$requested" TILLER_MINOR_LIMIT="$limit" bash "$script")
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
check v1.9.9 2.0.0 '' 9
check v1.8.9 1.9.0 '' 9
check v2.0.0 2.0.1 '' 9

reject() {
  local repo
  repo="$(mktemp -d)"
  git -C "$repo" init -q
  git -C "$repo" config user.name test
  git -C "$repo" config user.email test@example.com
  git -C "$repo" commit --allow-empty -qm init
  git -C "$repo" tag v1.0.0
  if (cd "$repo" && TILLER_VERSION="$1" bash "$script" >/dev/null 2>&1); then
    echo "expected rejection of $1" >&2; exit 1
  fi
  rm -rf "$repo"
}
reject 1.0.0
reject 1.0.10
reject 1.02.0
reject '1.0.1; false'
echo "version tests passed"
