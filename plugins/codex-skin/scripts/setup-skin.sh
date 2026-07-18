#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME="salary-cat"
PORT="9335"
DESKTOP_DIR="$HOME/Desktop"
STATE_ROOT="$HOME/Library/Application Support/Codex Skin"
DEFER_LABEL="com.mcgfdata.codex-skin.deferred-start"
DEFER_SCRIPT="$STATE_ROOT/deferred-start.sh"
DEFER_LOG="$STATE_ROOT/deferred-start.log"
DEFER_PLIST="$HOME/Library/LaunchAgents/$DEFER_LABEL.plist"
DEFER_COMPLETED_PLIST="$STATE_ROOT/deferred-start.completed.plist"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --theme) THEME="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

main_pids() {
  ps -axo pid=,command= | awk '/\/ChatGPT\.app\/Contents\/MacOS\/ChatGPT([[:space:]]|$)/ { print $1 }'
}

test_codex_debug_port() {
  local payload
  payload="$(curl --silent --show-error --fail --max-time 1 "http://127.0.0.1:$PORT/json/list" 2>/dev/null)" || return 1
  printf '%s' "$payload" | node -e '
    let data=""; process.stdin.on("data", c => data += c); process.stdin.on("end", () => {
      try { const rows=JSON.parse(data); process.exit(rows.some(x => x.type === "page" && String(x.url).startsWith("app://")) ? 0 : 1); }
      catch { process.exit(1); }
    });' >/dev/null 2>&1
}

write_deferred_start() {
  mkdir -p "$STATE_ROOT" "$HOME/Library/LaunchAgents"
  cat > "$DEFER_SCRIPT" <<EOF
#!/bin/bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

SCRIPT_DIR="$SCRIPT_DIR"
THEME="$THEME"
PORT="$PORT"
LOG="$DEFER_LOG"
PLIST="$DEFER_PLIST"
COMPLETED_PLIST="$DEFER_COMPLETED_PLIST"
LABEL="$DEFER_LABEL"

main_pids() {
  /bin/ps -axo pid=,command= | /usr/bin/awk '/\\/ChatGPT\\.app\\/Contents\\/MacOS\\/ChatGPT([[:space:]]|$)/ { print \$1 }'
}

{
  printf '%s waiting for Codex to exit before starting codex-skin theme %s\\n' "\$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" "\$THEME"
  while [ -n "\$(main_pids)" ]; do
    /bin/sleep 2
  done
  "\$SCRIPT_DIR/install-skin.sh" --theme "\$THEME" --port "\$PORT" --no-shortcuts
  "\$SCRIPT_DIR/start-skin.sh" --theme "\$THEME" --port "\$PORT"
  printf '%s codex-skin theme %s started\\n' "\$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" "\$THEME"
  /bin/mv "\$PLIST" "\$COMPLETED_PLIST" 2>/dev/null || true
  /bin/launchctl bootout "gui/\$(/usr/bin/id -u)/\$LABEL" 2>/dev/null || true
  /bin/launchctl bootout "gui/\$(/usr/bin/id -u)" "\$COMPLETED_PLIST" 2>/dev/null || true
} >>"\$LOG" 2>&1
EOF
  chmod 700 "$DEFER_SCRIPT"

  cat > "$DEFER_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$DEFER_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$DEFER_SCRIPT</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$STATE_ROOT/deferred-launchagent.out.log</string>
  <key>StandardErrorPath</key>
  <string>$STATE_ROOT/deferred-launchagent.err.log</string>
</dict>
</plist>
EOF
  launchctl bootout "gui/$(id -u)/$DEFER_LABEL" 2>/dev/null || true
  launchctl bootout "gui/$(id -u)" "$DEFER_PLIST" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$DEFER_PLIST"
}

"$SCRIPT_DIR/install-skin.sh" --theme "$THEME" --port "$PORT"

mkdir -p "$DESKTOP_DIR"
printf '#!/bin/bash\nexec %q --theme %q --port %q\n' \
  "$SCRIPT_DIR/start-skin.sh" "$THEME" "$PORT" > "$DESKTOP_DIR/Codex Skin.command"
printf '#!/bin/bash\nexec %q --theme %q --port %q\n' \
  "$SCRIPT_DIR/restart-skin.sh" "$THEME" "$PORT" > "$DESKTOP_DIR/Codex Skin - Restart.command"
printf '#!/bin/bash\nexec %q --port %q\n' \
  "$SCRIPT_DIR/restore-skin.sh" "$PORT" > "$DESKTOP_DIR/Codex Skin - Restore.command"

chmod +x \
  "$DESKTOP_DIR/Codex Skin.command" \
  "$DESKTOP_DIR/Codex Skin - Restart.command" \
  "$DESKTOP_DIR/Codex Skin - Restore.command"

echo "Codex Skin setup complete."
echo "Desktop launchers:"
echo "  $DESKTOP_DIR/Codex Skin.command"
echo "  $DESKTOP_DIR/Codex Skin - Restart.command"
echo "  $DESKTOP_DIR/Codex Skin - Restore.command"

if test_codex_debug_port; then
  "$SCRIPT_DIR/start-skin.sh" --theme "$THEME" --port "$PORT"
  echo "Codex Skin theme '$THEME' is active."
elif [[ -n "$(main_pids)" ]]; then
  write_deferred_start
  osascript -e 'display notification "请现在退出 Codex（Cmd+Q）。重新打开后会看到月薪喵皮肤。" with title "Codex Skin 已安装"' >/dev/null 2>&1 || true
  echo
  echo "Codex Skin has been installed, but the current Codex window was opened without the skin injector."
  echo "请现在退出 Codex（Cmd+Q）。退出后 Codex Skin 会自动重新启动 Codex。"
  echo "重启完成后应能看到 '$THEME' / 月薪喵 的图片皮肤。"
  echo "Deferred log: $DEFER_LOG"
else
  "$SCRIPT_DIR/start-skin.sh" --theme "$THEME" --port "$PORT"
  echo "Codex Skin theme '$THEME' is active."
fi
