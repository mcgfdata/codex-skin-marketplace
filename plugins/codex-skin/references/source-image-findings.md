# Source image findings

The files currently placed in `assets/source/` are Codex UI screenshots, not clean theme backgrounds.

## Local files

| File | Visual direction | Finding |
| --- | --- | --- |
| `IMG_3294.JPG` | Jackson Yee / herbal light theme | Matches the Codex skin gallery style. Use as reference only. |
| `IMG_3295.JPG` | Fiona Sit / pink-purple theme | Overlaps with the existing `dream` direction. Use as reference only. |
| `IMG_3296.JPG` | KUN / black-gold stage theme | Overlaps with the existing `kun-stage` direction. Use as reference only. |
| `IMG_3297.JPG` | Rick and Morty / green sci-fi theme | Found as a GitHub gallery direction. Use as reference only unless a no-UI theme package is available. |
| `IMG_3298.JPG` | Hatsune Miku / cyan virtual singer theme | Found in the Fei-Away gallery direction. Use as reference only. |
| `IMG_3299.JPG` | Rose portrait theme | Similar to Fei-Away romantic rose concept and preset documentation. Check rights before use. |
| `IMG_3300.JPG` | God of Wealth at Work | Found in the Fei-Away gallery direction. Use as reference only. |
| `IMG_3306.JPG` | ENFP inspiration micro-universe | Found in the Fei-Away gallery direction. Use as reference only. |

## Online matches

- `codexskin.io` indexes GitHub Codex skin screenshots and links them back to source repositories.
- `Fei-Away/Codex-Dream-Skin` documents the eight concept screenshots and says they are not directly importable backgrounds.
- `kongxcer555/codex-skin-builder` provides a MIT-licensed scaffold for generating independent macOS skin packages, but its demo screenshots and character artwork are not automatically reusable.

## Recommended action

Do not commit UI screenshots from `assets/source/` as public theme assets until rights are confirmed. Use them to generate or locate clean no-UI backgrounds, then import the resulting package with:

```bash
node scripts/import-external-theme.mjs --source /absolute/theme-package --mode auto
```
