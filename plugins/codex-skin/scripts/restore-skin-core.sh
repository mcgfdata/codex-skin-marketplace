#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common-macos.sh"
INJECTOR="$SCRIPT_DIR/injector.mjs"
STATE_ROOT="$CODEX_SKIN_STATE_ROOT"
STATE_PATH="$STATE_ROOT/state.json"
CONFIG_PATH="$HOME/.codex/config.toml"
BACKUP_PATH="$STATE_ROOT/config.before-codex-skin.toml"
DEFER_LABEL="com.mcgfdata.codex-skin.deferred-start"
DEFER_SCRIPT="$STATE_ROOT/deferred-start.sh"
DEFER_PLIST="$HOME/Library/LaunchAgents/$DEFER_LABEL.plist"
DEFER_COMPLETED_PLIST="$STATE_ROOT/deferred-start.completed.plist"
PORT=""
UNINSTALL=0
RESTORE_BASE=0
NODE_BIN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) PORT="$2"; shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    --restore-base-theme) RESTORE_BASE=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

safe_stop_injector() {
  local pid="$1" expected_path="${2:-$INJECTOR}" command
  [[ "$pid" =~ ^[0-9]+$ ]] || return 0
  [[ "$expected_path" == /*/scripts/injector.mjs ]] || return 0
  command="$(ps -p "$pid" -o command= 2>/dev/null || true)"
  if [[ "$command" == *"$expected_path"* && "$command" == *"--watch"* ]]; then
    kill "$pid" 2>/dev/null || true
    for _ in $(seq 1 20); do
      kill -0 "$pid" 2>/dev/null || return 0
      sleep 0.1
    done
    command="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    if [[ "$command" == *"$expected_path"* && "$command" == *"--watch"* ]]; then
      kill -KILL "$pid" 2>/dev/null || true
    fi
  fi
}

cancel_deferred_start() {
  launchctl remove "$DEFER_LABEL" 2>/dev/null || true
  launchctl bootout "gui/$(id -u)/$DEFER_LABEL" 2>/dev/null || true
  launchctl bootout "gui/$(id -u)" "$DEFER_PLIST" 2>/dev/null || true
  rm -f "$DEFER_PLIST" "$DEFER_COMPLETED_PLIST" "$DEFER_SCRIPT"
}

cancel_deferred_start
NODE_BIN="$(resolve_codex_node)" || { echo "Codex bundled Node.js or Node.js 20+ is required." >&2; exit 1; }
launchctl remove "$CODEX_SKIN_INJECTOR_LABEL" 2>/dev/null || true

if [[ -f "$STATE_PATH" ]]; then
  STATE_VALUES="$("$NODE_BIN" -e 'try { const s=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); console.log(`${s.port || ""}\t${s.injectorPid || ""}\t${s.injectorPath || (s.skillRoot ? `${s.skillRoot}/scripts/injector.mjs` : "")}`) } catch {}' "$STATE_PATH")"
  STATE_PORT="${STATE_VALUES%%$'\t'*}"
  STATE_REST="${STATE_VALUES#*$'\t'}"
  STATE_PID="${STATE_REST%%$'\t'*}"
  STATE_INJECTOR="${STATE_REST#*$'\t'}"
  [[ -z "$PORT" ]] && PORT="$STATE_PORT"
  [[ -n "$STATE_PID" ]] && safe_stop_injector "$STATE_PID" "$STATE_INJECTOR"
  rm -f "$STATE_PATH"
fi
PORT="${PORT:-9335}"
sleep 0.25
"$NODE_BIN" "$INJECTOR" --remove --port "$PORT" --timeout-ms 3000 >/dev/null 2>&1 || true

if [[ "$UNINSTALL" -eq 1 ]]; then
  rm -f "$HOME/Desktop/Codex Skin.command" "$HOME/Desktop/Codex Skin - Restart.command" "$HOME/Desktop/Codex Skin - Restore.command"
fi
if [[ "$RESTORE_BASE" -eq 1 ]]; then
  [[ -f "$BACKUP_PATH" ]] || { echo "No pre-install config backup is available." >&2; exit 1; }
  "$NODE_BIN" "$SCRIPT_DIR/theme-tool.mjs" restore --config "$CONFIG_PATH" --backup "$BACKUP_PATH"
fi
echo "The live Codex Skin was removed."
