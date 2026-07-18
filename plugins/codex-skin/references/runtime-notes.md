# Runtime notes

## Shared runtime

- Windows launches the newest Store-installed `OpenAI.Codex` package executable at `<InstallLocation>\app\ChatGPT.exe`. Never persist a versioned WindowsApps path.
- macOS launches the signed app with bundle id `com.openai.codex`, normally `/Applications/ChatGPT.app/Contents/MacOS/ChatGPT`. Also check `~/Applications` and Spotlight results for nonstandard installs.
- Both launchers pass `--remote-debugging-address=127.0.0.1` and `--remote-debugging-port=<port>` and inject through CDP.
- The default port is `9335`; isolated tests may use another port plus a separate user-data directory.
- The injector polls `app://` page targets and reinjects after document loads. In-page route changes use a debounced observer plus a five-second safety check.
- A watcher PID is stopped only when its current command line still identifies this injector in watch mode. Never terminate an unrelated PID merely because it appears in a stale state file.
- Watcher shutdown is bounded: request a graceful CDP disconnect first, then force-stop only the same verified injector PID if it remains alive.
- If Codex is already running without the selected debugging port, close it or explicitly authorize `-RestartExisting` / `--restart-existing`.
- The macOS deferred installer records the original Codex PID set. After those processes exit, it restarts any ordinary process that won the LaunchServices race and only reports success after CDP and theme verification pass.
- Cold-start verification allows the native renderer up to two minutes to finish restoring a task. The one-time LaunchAgent removes itself on both success and failure.
- The launchers rediscover the installed executable, but a Codex UI update may still change DOM selectors. Rerun screenshot verification after each app update.

## Script controller

- Direct `.mjs` workflows require Node.js with global `fetch`, `WebSocket`, and `AbortSignal.timeout`.
- Windows script state and logs live under the configured local app-data state directory.
- macOS script state and logs live under the configured application-support state directory.
- The platform installers back up `~/.codex/config.toml` before changing the supported `[desktop]` appearance keys. Before writing, all existing occurrences of each managed appearance key are removed so the resulting TOML never contains duplicate `appearanceTheme`, `appearanceLightCodeThemeId`, or `appearanceLightChromeTheme` entries.

## Troubleshooting

- A listener on port `9335` that does not expose an `app://` page target is not a valid Codex session; stop and report the port conflict.
- Executable discovery proves installation only. It does not prove current DOM compatibility.
- A successful injection call is insufficient: verify the theme marker, selected theme ID/version, native home controls, sidebar, composer, and a normal task.
