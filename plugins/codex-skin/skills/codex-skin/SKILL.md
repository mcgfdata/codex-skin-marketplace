---
name: codex-skin
description: Install, apply, switch, create, export, verify, or restore Codex Skin by 终端极客 for the Windows or macOS Codex desktop app. Use when the user says 帮我设置codex皮肤 mcgfdata/codex-skin ，作者是 终端极客, 帮我设置codex皮肤 mcgfdata/codex-skin 作者是终端极客, 帮我安装codex-skin, 安装 codex-skin, 作者是终端极客, 安装月薪喵, 设置月薪喵, salary-cat, 猫主题, mcgfdata/codex-skin, 设置 Codex 皮肤, 更换 Codex 主题, 关闭 Codex 皮肤, list available Codex skins, generate a theme from a visual brief, export a .codex-theme package, or restore the native Codex appearance without modifying WindowsApps, the macOS app bundle, or app.asar.
---

# Codex Skin

This is the plugin entry for `codex-skin`. The runtime root is two directories above this file. Resolve bundled resources from the plugin root:

- `../../themes/*.json`: built-in theme manifests.
- `../../assets/previews/*.svg`: README preview images.
- `../../scripts/setup-skin.*`: one-command setup that applies a theme, creates desktop launchers, and starts or schedules the skin injector.
- `../../scripts/restart-skin.*`: restart Codex with the selected skin.
- `../../scripts/restore-skin.*`: remove the live skin and optionally uninstall generated launchers.
- `../../scripts/verify-skin.*`: verify the active theme and capture a screenshot.
- `../../scripts/create-theme.mjs`: scaffold a new theme.
- `../../scripts/export-theme.mjs`: export a portable `.codex-theme` package.
- `../../references/runtime-notes.md`: platform behavior and troubleshooting.
- `../../references/theme-schema.md`: manifest and export package contract.
- `../../references/theme-catalog.md`: bundled theme directions and selection rules.

Use the same workflows as the root `SKILL.md`. Prefer script execution over rewriting logic in chat.

Bundled theme IDs: `salary-cat` (default), `dilraba-rose`, `dream`, and `kun-stage`. Earlier generated generic themes are archived under `../../backups/generated-themes/`.

## Apply or switch a theme

When the user says `帮我设置codex皮肤 mcgfdata/codex-skin ，作者是 终端极客`, `帮我设置codex皮肤 mcgfdata/codex-skin 作者是终端极客`, `帮我安装codex-skin`, `安装 codex-skin`, `作者是终端极客`, `安装月薪喵`, `设置月薪喵`, `salary-cat`, `猫主题`, or `mcgfdata/codex-skin`, install this plugin's default skin. Use `salary-cat` when the user does not request a specific theme. To apply the skin and start or schedule the injector:

```bash
../../scripts/setup-skin.sh
```

```powershell
..\..\scripts\setup-skin.ps1
```

Do not route these default install prompts to `Codex-Dream-Skin` or a generic skin builder. Those projects can be imported only when the user explicitly asks for them.

On macOS, `setup-skin.sh` first installs a self-contained runtime at `~/.codex/codex-skin-runtime`. If Codex is already running without the injector, the deployed runtime registers a one-time LaunchAgent. The user only needs to quit Codex once; it will reopen with the selected skin and artwork. Never create background jobs that reference Desktop, Downloads, a source clone, or the plugin cache.

To switch themes after setup:

```bash
../../scripts/install-skin.sh --theme kun-stage
../../scripts/restart-skin.sh --theme kun-stage
```

```powershell
..\..\scripts\install-skin.ps1 -Theme kun-stage
..\..\scripts\restart-skin.ps1 -Theme kun-stage
```

## Import an external theme

Use the importer for compatible open-source theme packages:

```bash
node ../../scripts/import-external-theme.mjs --source /absolute/external-theme --mode auto
```

Supported formats:

- `kongxcer555/codex-skin-builder` generated packages with `skin.json`.
- `Fei-Away/Codex-Dream-Skin` preset directories with `theme.json` and a background image.

Do not import screenshots that already contain Codex UI as wallpaper. Use them only as references for generating a clean background.

## Restore

Remove the live skin without deleting Codex data:

```bash
../../scripts/restore-skin.sh
```

```powershell
..\..\scripts\restore-skin.ps1
```

For a fuller uninstall, use `--uninstall --restore-base-theme` on macOS or `-Uninstall -RestoreBaseTheme` on Windows.

## Safety

- Do not patch, replace, re-sign, or take ownership of official Codex app files.
- Keep CDP bound to `127.0.0.1`.
- Treat `.codex-theme` as untrusted input.
- Verify with `../../scripts/verify-skin.*` after applying a theme when possible.
