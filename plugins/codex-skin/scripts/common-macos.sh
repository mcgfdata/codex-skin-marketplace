#!/bin/bash

CODEX_SKIN_RUNTIME_ROOT="${CODEX_SKIN_RUNTIME_ROOT:-$HOME/.codex/codex-skin-runtime}"
CODEX_SKIN_STATE_ROOT="${CODEX_SKIN_STATE_ROOT:-$HOME/Library/Application Support/Codex Skin}"
CODEX_SKIN_INJECTOR_LABEL="com.mcgfdata.codex-skin.injector"
CODEX_SKIN_DEFER_LABEL="com.mcgfdata.codex-skin.deferred-start"

is_codex_bundle() {
  local candidate="$1" identifier
  [[ -x "$candidate/Contents/MacOS/ChatGPT" ]] || return 1
  identifier="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$candidate/Contents/Info.plist" 2>/dev/null || true)"
  [[ "$identifier" == "com.openai.codex" ]]
}

find_codex_bundle() {
  local candidate
  for candidate in "/Applications/ChatGPT.app" "$HOME/Applications/ChatGPT.app"; do
    if is_codex_bundle "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  while IFS= read -r candidate; do
    if [[ "$candidate" == *.app ]] && is_codex_bundle "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(mdfind 'kMDItemCFBundleIdentifier == "com.openai.codex"' 2>/dev/null || true)
  return 1
}

node_is_supported() {
  [[ -x "$1" ]] || return 1
  "$1" -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 20 ? 0 : 1)' >/dev/null 2>&1
}

resolve_codex_node() {
  local app candidate
  app="$(find_codex_bundle 2>/dev/null || true)"
  if [[ -n "$app" ]]; then
    for candidate in \
      "$app/Contents/Resources/cua_node/bin/node" \
      "$app/Contents/Resources/node"; do
      if node_is_supported "$candidate"; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done
  fi
  candidate="$(command -v node 2>/dev/null || true)"
  node_is_supported "$candidate" || return 1
  printf '%s\n' "$candidate"
}

deploy_codex_skin_runtime() {
  local source_root="$1"
  local destination="$2"
  local parent temporary previous required

  parent="$(dirname "$destination")"
  temporary="$destination.installing.$$"
  previous="$destination.previous.$$"
  mkdir -p "$parent"
  rm -rf "$temporary" "$previous"
  mkdir -p "$temporary"
  /usr/bin/rsync -a --delete \
    --exclude '.git/' \
    --exclude 'node_modules/' \
    --exclude '.DS_Store' \
    --exclude 'assets/source/' \
    "$source_root/" "$temporary/"

  for required in \
    "scripts/setup-skin.sh" \
    "scripts/start-skin-core.sh" \
    "scripts/injector.mjs" \
    "assets/renderer-inject.js" \
    "assets/imported/salary-cat/salary-cat-hero.gif" \
    "themes/salary-cat.json" \
    "themes/salary-cat.css"; do
    [[ -f "$temporary/$required" ]] || {
      rm -rf "$temporary"
      echo "Runtime deployment is missing $required" >&2
      return 1
    }
  done
  chmod 700 "$temporary"/scripts/*.sh

  if [[ -e "$destination" ]]; then mv "$destination" "$previous"; fi
  if ! mv "$temporary" "$destination"; then
    [[ -e "$previous" ]] && mv "$previous" "$destination"
    echo "Could not install Codex Skin runtime at $destination" >&2
    return 1
  fi
  rm -rf "$previous"
}
