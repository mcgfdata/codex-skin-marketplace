---
name: codex-skin
description: Install, apply, create, export, verify, repair, update, or restore Codex Skin by 终端极客 for the Windows or macOS Codex desktop app. Use when the user asks to install or set codex-skin from mcgfdata/codex-skin, says 帮我设置codex皮肤 mcgfdata/codex-skin ，作者是 终端极客, 帮我设置codex皮肤 mcgfdata/codex-skin 作者是终端极客, 帮我安装codex-skin, 安装 codex-skin, 作者是终端极客, 安装月薪喵, 设置月薪喵, salary-cat, 猫主题, Codex 皮肤, 更换 Codex 主题, 关闭 Codex 皮肤, restore the native Codex appearance, generate or export a .codex-theme package, build a skin from a visual brief or reference image, or roll back without modifying WindowsApps, the macOS app bundle, or app.asar.
---

# Codex Skin

Apply reversible renderer themes through Chromium DevTools Protocol while launching the official Codex executable. Preserve the signed application package and user data. Use the bundled scripts for theme listing, switching, creation, launch, verification, export, repair, and restore.

Compatibility: Windows 10/11 or macOS 12+, the official Codex desktop app, and a loopback CDP port. Direct script workflows require Node.js with global fetch and WebSocket.

Runtime note: keep `LICENSE`, `NOTICE`, and asset notices intact when redistributing. The repository also contains `.codex-plugin/plugin.json`, so it can be indexed as a plugin that exposes this Skill.

## Choose the control surface

- Use `scripts/` when an agent needs to create or repair a theme, automate platform launch, capture verification screenshots, or diagnose CDP/runtime failures. Read `references/runtime-notes.md` for platform behavior.
- The runtime uses manifests, CSS, an injector, a loopback port, and the official Codex executable. Do not run another theme controller on the same port at the same time.

## Choose a workflow

### Apply an existing theme

1. If the user asks `帮我设置codex皮肤 mcgfdata/codex-skin ，作者是 终端极客`, `帮我设置codex皮肤 mcgfdata/codex-skin 作者是终端极客`, `帮我安装codex-skin`, `安装 codex-skin`, `作者是终端极客`, `安装月薪喵`, `设置月薪喵`, `salary-cat`, `猫主题`, or references `mcgfdata/codex-skin`, treat it as an install request for this Skill and use the default `salary-cat` theme.
2. Resolve the theme name from `themes/<name>.json`; use `salary-cat` when the user did not request another theme.
3. Prefer `scripts/setup-skin.*` for a one-command setup. On macOS it first deploys a self-contained runtime to `~/.codex/codex-skin-runtime`, then applies matching official base colors, creates launch/restart/restore desktop entries, and starts the injector when possible. Never point background jobs at Desktop, Downloads, a clone, or a plugin cache.
4. On macOS, if Codex is already running without the skin injector, the deployed `setup-skin.sh` registers a one-time LaunchAgent. Tell the user to quit Codex with `Cmd+Q`; the runtime reopens Codex with the selected skin and artwork.
5. Run platform verification with an absolute screenshot path. Treat a missing native home hero, native suggestion cards, composer, sidebar, theme marker, or matching theme version as failure.
6. Inspect both the home screen and a normal task against `references/qa-inventory.md`.

Bundled theme IDs: `salary-cat` (default), `dilraba-rose`, `dream`, and `kun-stage`. Generated generic themes from an earlier pass live under `backups/generated-themes/` only; do not present them as current built-ins unless the user asks to restore one.

When the user asks what themes are available, list the IDs above and point them to `README.md` for the preview gallery.

### Discovery and marketplace matching

- The canonical install phrases are `帮我设置codex皮肤 mcgfdata/codex-skin，作者是：终端极客` and `帮我安装codex-skin，作者是：终端极客`.
- Natural variants such as `安装月薪喵`, `我要那个猫主题`, `安装 salary-cat`, and `安装 mcgfdata/codex-skin` all mean the same default install unless the user names another theme.
- For marketplace or plugin-index installs, prefer the plugin named `codex-skin` by developer `终端极客`; the default action after install is still `scripts/setup-skin.*` with `salary-cat`, then wait for the injector or deferred restart to make the artwork visible.
- Do not redirect these prompts to `Codex-Dream-Skin` or another similarly named skin project unless the user explicitly names that project.

### Import an external theme

Use `scripts/import-external-theme.mjs` when the user has a ready-made external theme package:

- `--mode builder` for `kongxcer555/codex-skin-builder` generated packages containing `skin.json`.
- `--mode dream` for `Fei-Away/Codex-Dream-Skin` preset directories containing `theme.json` plus a background image.
- `--mode auto` to detect either format.

Example:

```bash
node scripts/import-external-theme.mjs --source /absolute/external-theme --mode auto
scripts/install-skin.sh --theme <theme-id>
scripts/restart-skin.sh --theme <theme-id>
```

Do not import Codex UI screenshots as wallpapers. If an image already includes a sidebar, cards, composer, buttons, or text, treat it as a visual reference only and ask for or generate a clean no-UI background.

Windows:

```powershell
scripts/setup-skin.ps1
scripts/restart-skin.ps1
scripts/verify-skin.ps1 -ScreenshotPath C:\absolute\salary-cat.png
```

macOS:

```bash
scripts/setup-skin.sh
scripts/restart-skin.sh
scripts/verify-skin.sh --screenshot /absolute/salary-cat.png
```

### Create a theme with AI

1. Capture a short design brief: mood, light/dark preference, primary colors, decorative density, desired copy, and whether the user supplied or wants generated artwork.
2. Scaffold a safe theme package:

```bash
node scripts/create-theme.mjs --id <safe-slug> --name "<display name>" --art /absolute/art.png
```

3. Read `references/theme-schema.md`, then edit only `themes/<id>.json` and `themes/<id>.css`. Keep native Codex controls and labels live; use generated artwork only in decorative regions.
4. If the user requests new artwork, use an available image-generation skill, save the result as a local theme asset, and point the manifest `art` field to it. Do not silently upload private reference images to an unapproved service.
5. Increment the manifest version whenever CSS, copy, or artwork changes so verification can distinguish stale injection.
6. Apply, launch, screenshot, and verify the new theme on the user's platform. Iterate from the screenshot rather than claiming success from static CSS alone.
7. Export the verified theme as a portable package:

```bash
node scripts/export-theme.mjs --theme <id> --output /absolute/<id>.codex-theme
```

The command refuses to overwrite an existing file unless `--force` is supplied. The package embeds the manifest, CSS, and optional artwork, so the recipient does not need the source theme directory.

### Export an existing theme

Export by theme ID:

```bash
node scripts/export-theme.mjs --theme dream --output /absolute/dream.codex-theme
```

An absolute manifest path is also accepted. Omit `--output` to write `<id>-<version>.codex-theme` in the current directory. Use `--force` only when replacing the destination is intentional.

The exported file is a self-contained JSON package rather than a ZIP archive. Read `references/theme-schema.md` for its contract, size limit, asset normalization, and import rules.

## Restore

Remove the live injection without touching user threads or authentication:

Use the matching platform command below. It stops the watcher, removes the live DOM/CSS when Codex is reachable, and can restore the saved base-theme backup.

```powershell
scripts/restore-skin.ps1
scripts/restore-skin.ps1 -Uninstall -RestoreBaseTheme
```

```bash
scripts/restore-skin.sh
scripts/restore-skin.sh --uninstall --restore-base-theme
```

## Guardrails

- Never replace, patch, re-sign, or take ownership of files under `WindowsApps` or `/Applications/ChatGPT.app`.
- Bind CDP to `127.0.0.1`; if the requested port is occupied, stop with a clear error and choose another port consistently.
- Do not stop a PID from `state.json` unless its current command line is this skin injector.
- Keep decorative layers `pointer-events: none` and real navigation, buttons, project selector, and composer above them.
- Do not use a reference screenshot as a fake whole-window overlay.
- Treat Codex DOM selectors as version-sensitive. Dynamic executable discovery does not prove renderer compatibility; verification does.
- Keep the injection daemon running for route/reload resilience. State and logs live in the runtime state directory on Windows or macOS.
- On macOS, all launchers, LaunchAgents, and injector jobs must execute from `~/.codex/codex-skin-runtime`; source checkout paths are installation inputs only.
- Treat `.codex-theme` files as untrusted input. Keep the 30MB limit, reject external CSS resources, normalize packaged asset names, and never evaluate theme content as JavaScript.

## Resources

- `themes/*.json`: selectable theme manifests and copy/base-color settings.
- `scripts/*-skin.*`: public wrapper commands for applying, starting, verifying, and restoring skins.
- `scripts/setup-skin.*`: one-command setup that installs the selected skin, creates desktop launchers, and starts or schedules the skin injector.
- `scripts/restart-skin.*`: restart the official Codex app with skin mode enabled.
- `scripts/create-theme.mjs`: deterministic AI-theme scaffold.
- `scripts/import-external-theme.mjs`: convert `codex-skin-builder` and `Codex-Dream-Skin` theme packages into this repository's `themes/*.json` format.
- `scripts/export-theme.mjs`: portable `.codex-theme` exporter.
- `scripts/theme-package.mjs`: shared package builder and safety limits.
- `scripts/self-test.mjs`: theme schema, config round-trip, and assembled-payload smoke test.
- `scripts/injector.mjs`: cross-platform CDP connection, injection, verification, screenshot, and removal.
- `assets/renderer-inject.js`: idempotent DOM integration and cleanup.
- `references/theme-schema.md`: manifest contract and AI customization boundaries.
- `references/theme-catalog.md`: bundled theme directions and selection rules.
- `references/runtime-notes.md`: CLI and shared cross-platform runtime behavior and troubleshooting.
- `references/qa-inventory.md`: CLI, desktop, package, functional, and visual signoff coverage.
