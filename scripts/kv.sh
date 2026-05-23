#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER="${REDIS_CONTAINER:-beam-gate-redis}"

if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ROOT/.env"
  set +a
fi

redis_cli() {
  if [[ -n "${REDIS_PASSWORD:-}" ]]; then
    docker exec "$CONTAINER" redis-cli -a "$REDIS_PASSWORD" "$@"
  else
    docker exec "$CONTAINER" redis-cli "$@"
  fi
}

usage() {
  cat <<EOF
Simple Redis key-value helper

Usage:
  ./scripts/kv.sh set <key> <value>
  ./scripts/kv.sh get <key>
  ./scripts/kv.sh del <key>
  ./scripts/kv.sh keys [pattern]
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

command="$1"
shift

case "$command" in
  set)
    [[ $# -eq 2 ]] || { echo "Usage: $0 set <key> <value>"; exit 1; }
    redis_cli SET "$1" "$2"
  ;;
  get)
    [[ $# -eq 1 ]] || { echo "Usage: $0 get <key>"; exit 1; }
    redis_cli GET "$1"
  ;;
  del)
    [[ $# -eq 1 ]] || { echo "Usage: $0 del <key>"; exit 1; }
    redis_cli DEL "$1"
  ;;
  keys)
    pattern="${1:-*}"
    redis_cli KEYS "$pattern"
  ;;
  *)
    usage
    exit 1
  ;;
esac
