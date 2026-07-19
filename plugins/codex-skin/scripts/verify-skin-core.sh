#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common-macos.sh"
PORT=9335
THEME=salary-cat
SCREENSHOT=""
RELOAD=0
NODE_BIN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) PORT="$2"; shift 2 ;;
    --theme) THEME="$2"; shift 2 ;;
    --screenshot) SCREENSHOT="$2"; shift 2 ;;
    --reload) RELOAD=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

ARGS=("$SCRIPT_DIR/injector.mjs" --verify --port "$PORT" --theme "$THEME")
[[ -n "$SCREENSHOT" ]] && ARGS+=(--screenshot "$SCREENSHOT")
[[ "$RELOAD" -eq 1 ]] && ARGS+=(--reload)
NODE_BIN="$(resolve_codex_node)" || { echo "Codex bundled Node.js or Node.js 20+ is required." >&2; exit 1; }
exec "$NODE_BIN" "${ARGS[@]}"
