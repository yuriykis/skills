#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"

if [[ ! -d "$root" ]]; then
  printf 'unknown\n'
  exit 0
fi

versions=$(find "$root" -name go.mod -type f -print0 2>/dev/null \
  | xargs -0 awk '/^go[[:space:]]+[0-9]+\.[0-9]+/ { print $2 }' 2>/dev/null \
  | sort \
  | uniq -c \
  | sort -nr)

if [[ -z "$versions" ]]; then
  printf 'unknown\n'
  exit 0
fi

printf '%s\n' "$versions"
