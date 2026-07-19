#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
. "$SCRIPT_DIR/common-macos.sh"
INJECTOR="$SCRIPT_DIR/injector.mjs"
STATE_ROOT="$CODEX_SKIN_STATE_ROOT"
STATE_PATH="$STATE_ROOT/state.json"
STDOUT_PATH="$STATE_ROOT/injector.log"
STDERR_PATH="$STATE_ROOT/injector-error.log"
APP_LOG="$STATE_ROOT/app-launch.log"
PORT=9335
THEME=salary-cat
PROFILE_PATH=""
RESTART_EXISTING=0
FOREGROUND=0
NODE_BIN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) PORT="$2"; shift 2 ;;
    --theme) THEME="$2"; shift 2 ;;
    --profile-path) PROFILE_PATH="$2"; shift 2 ;;
    --restart-existing) RESTART_EXISTING=1; shift ;;
    --foreground-injector) FOREGROUND=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1024 && PORT <= 65535 )) || {
  echo "Invalid port: $PORT" >&2; exit 2;
}
NODE_BIN="$(resolve_codex_node)" || { echo "Codex bundled Node.js or Node.js 20+ is required." >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required." >&2; exit 1; }
mkdir -p "$STATE_ROOT"
"$NODE_BIN" "$SCRIPT_DIR/theme-tool.mjs" info --theme "$THEME" --platform darwin >/dev/null

test_codex_debug_port() {
  local payload
  payload="$(curl --silent --show-error --fail --max-time 1 "http://127.0.0.1:$PORT/json/list" 2>/dev/null)" || return 1
  printf '%s' "$payload" | "$NODE_BIN" -e '
    let data=""; process.stdin.on("data", c => data += c); process.stdin.on("end", () => {
      try { const rows=JSON.parse(data); process.exit(rows.some(x => x.type === "page" && String(x.url).startsWith("app://")) ? 0 : 1); }
      catch { process.exit(1); }
    });' >/dev/null 2>&1
}

main_pids() {
  ps -axo pid=,command= | awk '/\/ChatGPT\.app\/Contents\/MacOS\/ChatGPT([[:space:]]|$)/ { print $1 }'
}

launched_codex_is_running() {
  if [[ -z "$PROFILE_PATH" ]]; then
    [[ -n "$(main_pids)" ]]
    return
  fi
  ps -axo command= | awk -v profile="--user-data-dir=$PROFILE_PATH" '
    /\/ChatGPT\.app\/Contents\/MacOS\/ChatGPT([[:space:]]|$)/ && index($0, profile) { found=1 }
    END { exit found ? 0 : 1 }
  '
}

stop_running_codex() {
  local pid
  osascript -e 'tell application id "com.openai.codex" to quit' >/dev/null 2>&1 || true
  for _ in $(seq 1 60); do
    [[ -z "$(main_pids)" ]] && return 0
    sleep 0.2
  done
  while IFS= read -r pid; do
    [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
  done < <(main_pids)
  for _ in $(seq 1 20); do
    [[ -z "$(main_pids)" ]] && return 0
    sleep 0.1
  done
}

launch_codex_with_cdp() {
  local app_bundle="$1"
  local port="$2"
  shift 2
  local args=("--remote-debugging-address=127.0.0.1" "--remote-debugging-port=$port" "$@")

  : >"$APP_LOG"
  /usr/bin/open -na "$app_bundle" --args "${args[@]}" >>"$APP_LOG" 2>&1 || true

  # Give LaunchServices time to create the process. CDP readiness is checked
  # by the caller; an already-started app must not be killed just for loading
  # more slowly than this short fallback window.
  for _ in $(seq 1 20); do
    test_codex_debug_port && return 0
    launched_codex_is_running && return 0
    sleep 0.1
  done

  # Fallback only when LaunchServices did not start the application at all.
  nohup "$app_bundle/Contents/MacOS/ChatGPT" "${args[@]}" >>"$APP_LOG" 2>&1 &
}

safe_stop_injector() {
  local pid="$1" expected_path="${2:-$INJECTOR}" command
  [[ "$pid" =~ ^[0-9]+$ ]] || return 0
  [[ "$expected_path" == /*/scripts/injector.mjs ]] || return 0
  command="$(ps -p "$pid" -o command= 2>/dev/null || true)"
  if [[ "$command" == *"$expected_path"* && "$command" == *"--watch"* ]]; then
    launchctl remove "$CODEX_SKIN_INJECTOR_LABEL" 2>/dev/null || true
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

launch_injector_daemon() {
  local pid="" deadline
  : >"$STDOUT_PATH"
  : >"$STDERR_PATH"
  launchctl remove "$CODEX_SKIN_INJECTOR_LABEL" 2>/dev/null || true
  deadline=$((SECONDS + 10))
  if launchctl submit -l "$CODEX_SKIN_INJECTOR_LABEL" \
    -o "$STDOUT_PATH" -e "$STDERR_PATH" -- \
    "$NODE_BIN" "$INJECTOR" --watch --port "$PORT" --theme "$THEME" \
    >/dev/null 2>&1; then
    while [[ "$SECONDS" -lt "$deadline" ]]; do
      pid="$(launchctl print "gui/$(id -u)/$CODEX_SKIN_INJECTOR_LABEL" 2>/dev/null \
        | awk '/^[[:space:]]*pid = [0-9]+/{print $3; exit}')"
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        printf '%s\n' "$pid"
        return 0
      fi
      sleep 0.2
    done
    launchctl remove "$CODEX_SKIN_INJECTOR_LABEL" 2>/dev/null || true
  fi
  nohup "$NODE_BIN" "$INJECTOR" --watch --port "$PORT" --theme "$THEME" \
    >"$STDOUT_PATH" 2>"$STDERR_PATH" &
  pid=$!
  sleep 0.2
  kill -0 "$pid" 2>/dev/null || return 1
  printf '%s\n' "$pid"
}

if ! test_codex_debug_port && [[ -z "$PROFILE_PATH" ]] && [[ -n "$(main_pids)" ]]; then
  if [[ "$RESTART_EXISTING" -ne 1 ]]; then
    echo "Codex is already running without Codex Skin debugging on port $PORT." >&2
    echo "Close Codex or rerun with --restart-existing." >&2
    exit 1
  fi
  stop_running_codex
fi

if ! test_codex_debug_port; then
  if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Port $PORT is occupied by another process." >&2
    exit 1
  fi
  APP_BUNDLE="$(find_codex_bundle)" || { echo "Codex app with bundle id com.openai.codex was not found." >&2; exit 1; }
  ARGS=("--remote-debugging-address=127.0.0.1" "--remote-debugging-port=$PORT")
  if [[ -n "$PROFILE_PATH" ]]; then
    mkdir -p "$PROFILE_PATH"
    ARGS+=("--user-data-dir=$PROFILE_PATH")
  fi
  launch_codex_with_cdp "$APP_BUNDLE" "$PORT" "${ARGS[@]:2}"
fi

READY=0
for _ in $(seq 1 75); do
  if test_codex_debug_port; then READY=1; break; fi
  sleep 0.4
done
[[ "$READY" -eq 1 ]] || { echo "Codex did not expose CDP on port $PORT within 30 seconds." >&2; exit 1; }

if [[ -f "$STATE_PATH" ]]; then
  OLD_VALUES="$("$NODE_BIN" -e 'try { const s=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); console.log(`${s.injectorPid || ""}\t${s.injectorPath || (s.skillRoot ? `${s.skillRoot}/scripts/injector.mjs` : "")}`) } catch {}' "$STATE_PATH")"
  OLD_PID="${OLD_VALUES%%$'\t'*}"
  OLD_INJECTOR="${OLD_VALUES#*$'\t'}"
  [[ -n "$OLD_PID" ]] && safe_stop_injector "$OLD_PID" "$OLD_INJECTOR"
fi

if [[ "$FOREGROUND" -eq 1 ]]; then
  exec "$NODE_BIN" "$INJECTOR" --watch --port "$PORT" --theme "$THEME"
fi

DAEMON_PID="$(launch_injector_daemon)" || { echo "Codex Skin injector did not start. See $STDERR_PATH" >&2; exit 1; }
"$NODE_BIN" - "$STATE_PATH" "$PORT" "$DAEMON_PID" "$SKILL_ROOT" "$PROFILE_PATH" "$THEME" "$NODE_BIN" "$INJECTOR" <<'NODE'
const fs = require("fs");
const [statePath, port, injectorPid, skillRoot, profilePath, theme, nodePath, injectorPath] = process.argv.slice(2);
fs.writeFileSync(statePath, JSON.stringify({
  schemaVersion: 2, port: Number(port), injectorPid: Number(injectorPid), startedAt: new Date().toISOString(),
  skillRoot, profilePath, theme, nodePath, injectorPath, session: "applying",
}, null, 2));
NODE

VERIFIED=0
# A resumed task can keep the renderer busy well after CDP starts listening.
# Allow the native shell up to two minutes to expose the controls we verify.
for _ in $(seq 1 170); do
  sleep 0.7
  if "$NODE_BIN" "$INJECTOR" --verify --port "$PORT" --theme "$THEME" --timeout-ms 3000 >/dev/null 2>&1; then
    VERIFIED=1
    break
  fi
done
if [[ "$VERIFIED" -ne 1 ]]; then
  safe_stop_injector "$DAEMON_PID"
  rm -f "$STATE_PATH"
  echo "Codex Skin launched but verification failed. See $STDERR_PATH" >&2
  exit 1
fi
"$NODE_BIN" - "$STATE_PATH" <<'NODE'
const fs = require("fs");
const file = process.argv[2];
const state = JSON.parse(fs.readFileSync(file, "utf8"));
state.session = "active";
state.verifiedAt = new Date().toISOString();
fs.writeFileSync(file, JSON.stringify(state, null, 2));
NODE
echo "Codex Skin theme '$THEME' is active on port $PORT."
