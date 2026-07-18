# Theme catalog

This catalog records theme directions used by `codex-skin`. The project does not copy third-party theme files, logos, screenshots, or brand artwork unless the license and asset rights are explicit.

## Bundled themes

| ID | Direction | Notes |
| --- | --- | --- |
| `salary-cat` | Monthly Salary Cat / default | Converted from `kongxcer555/codex-skin-builder` reference skin. |
| `dream` | Existing custom skin | Image-backed light theme. |
| `kun-stage` | Existing custom skin | Image-backed dark stage theme. |
| `dilraba-rose` | Existing custom skin | Image-backed rose light theme. |

## Archived generated themes

The earlier generic engineering themes are archived under `backups/generated-themes/`:

- `catppuccin-mocha`
- `dracula`
- `github-light`
- `matrix-green`
- `nord-aurora`
- `ocean-calm`
- `rose-pine`
- `solarized-light`
- `tokyo-night`

They are preserved for later reuse, but they are not advertised as active built-in themes.

## External formats

`scripts/import-external-theme.mjs` supports:

- `kongxcer555/codex-skin-builder` generated packages with `skin.json`.
- `Fei-Away/Codex-Dream-Skin` preset directories with `theme.json` plus a background image.

Imported assets are copied under `assets/imported/<theme-id>/`, and generated manifests are written to `themes/<theme-id>.json`.

## Selection rules

- Prefer themes that users already recognize from editors, terminals, and GitHub workflows.
- Keep theme IDs lowercase and stable because users call them from scripts.
- Use local CSS and local preview images only.
- Do not add third-party logos, screenshots, celebrity artwork, or remote image URLs for new generic themes.
- Do not import Codex UI screenshots as wallpapers. Use no-UI backgrounds or a compatible external theme package.
