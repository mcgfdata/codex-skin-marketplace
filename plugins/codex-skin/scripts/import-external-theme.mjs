import fs from "node:fs/promises";
import path from "node:path";
import { skillRoot } from "./theme-lib.mjs";

const COLOR_FALLBACKS = {
  background: "#fff7fb",
  panel: "#ffffff",
  panelAlt: "#fff0f7",
  accent: "#b65cff",
  accentAlt: "#d986ff",
  secondary: "#f27ab8",
  highlight: "#ffe0f1",
  text: "#3c243f",
  muted: "#8b6f8e",
  line: "rgba(182, 92, 255, .26)",
};

function parseArgs(argv) {
  const options = { force: false, mode: "auto", preferAnimated: false };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--source") options.source = path.resolve(argv[++index]);
    else if (arg === "--id") options.id = argv[++index];
    else if (arg === "--name") options.name = argv[++index];
    else if (arg === "--mode") options.mode = argv[++index];
    else if (arg === "--prefer-animated") options.preferAnimated = true;
    else if (arg === "--force") options.force = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!options.source) throw new Error("Usage: node scripts/import-external-theme.mjs --source <theme-dir> [--mode auto|dream|builder] [--id theme-id] [--name display-name] [--force]");
  if (!["auto", "dream", "builder"].includes(options.mode)) throw new Error("--mode must be auto, dream, or builder");
  return options;
}

function slugify(value, fallback = "imported-theme") {
  const slug = String(value ?? "")
    .normalize("NFKD")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-{2,}/g, "-");
  return slug || fallback;
}

function cssString(value) {
  return JSON.stringify(String(value ?? ""));
}

function normalizeColor(value, fallback) {
  if (typeof value !== "string" || !value.trim()) return fallback;
  const trimmed = value.trim();
  if (/^#[0-9a-f]{3}(?:[0-9a-f]{3})?$/i.test(trimmed)) return trimmed;
  if (/^rgba?\([^)]+\)$/i.test(trimmed)) return trimmed;
  if (/^hsla?\([^)]+\)$/i.test(trimmed)) return trimmed;
  return fallback;
}

function quoteCssUrl(relativePath) {
  return relativePath.replace(/["\\]/g, "\\$&");
}

async function readJson(file) {
  return JSON.parse(await fs.readFile(file, "utf8"));
}

async function exists(file) {
  try {
    await fs.access(file);
    return true;
  } catch {
    return false;
  }
}

async function detectTheme(source, requestedMode) {
  const dreamManifest = path.join(source, "theme.json");
  const builderManifest = path.join(source, "skin.json");
  if ((requestedMode === "dream" || requestedMode === "auto") && await exists(dreamManifest)) {
    const theme = await readJson(dreamManifest);
    if (theme?.schemaVersion === 1 && typeof theme.image === "string") return { type: "dream", manifest: theme };
  }
  if ((requestedMode === "builder" || requestedMode === "auto") && await exists(builderManifest)) {
    const skin = await readJson(builderManifest);
    if (skin?.schemaVersion === 1 && (skin.preview || skin.animatedHero)) return { type: "builder", manifest: skin };
  }
  throw new Error("Unsupported external theme. Expected Codex-Dream-Skin theme.json or codex-skin-builder skin.json.");
}

function imageFromExternalTheme(source, detected, preferAnimated) {
  if (detected.type === "dream") return path.join(source, detected.manifest.image);
  const image = preferAnimated && detected.manifest.animatedHero
    ? detected.manifest.animatedHero
    : detected.manifest.preview || detected.manifest.animatedHero;
  return path.join(source, image);
}

function baseColorsFor(detected) {
  const colors = detected.manifest.colors ?? {};
  return Object.fromEntries(
    Object.entries(COLOR_FALLBACKS).map(([key, fallback]) => [key, normalizeColor(colors[key], fallback)]),
  );
}

function cssForTheme(id, colors) {
  return `:root.codex-skin[data-codex-skin-theme="${id}"] {
  color-scheme: ${colors.background === "#fff7fb" || colors.background === "#ffffff" ? "light" : "dark"} !important;
  --skin-bg: ${colors.background};
  --skin-panel: ${colors.panel};
  --skin-panel-alt: ${colors.panelAlt};
  --skin-accent: ${colors.accent};
  --skin-accent-alt: ${colors.accentAlt};
  --skin-secondary: ${colors.secondary};
  --skin-highlight: ${colors.highlight};
  --skin-text: ${colors.text};
  --skin-muted: ${colors.muted};
  --skin-line: ${colors.line};
  --color-token-foreground: var(--skin-text);
  --color-token-description-foreground: color-mix(in srgb, var(--skin-muted) 84%, transparent);
  --color-token-disabled-foreground: color-mix(in srgb, var(--skin-muted) 56%, transparent);
  --color-token-input-foreground: var(--skin-text);
  --color-token-input-placeholder-foreground: color-mix(in srgb, var(--skin-muted) 62%, transparent);
  --color-token-input-background: color-mix(in srgb, var(--skin-panel) 94%, transparent);
  --color-token-editor-foreground: var(--skin-text);
  --color-token-editor-background: var(--skin-bg);
  --color-token-terminal-foreground: var(--skin-text);
  --color-token-terminal-background: var(--skin-bg);
  --color-token-dropdown-foreground: var(--skin-text);
  --color-token-dropdown-background: var(--skin-panel);
  --color-token-menu-background: var(--skin-panel);
  --color-token-text-code-block-background: color-mix(in srgb, var(--skin-panel-alt) 88%, transparent);
  --color-token-badge-background: color-mix(in srgb, var(--skin-accent) 18%, transparent);
  --color-token-list-hover-background: color-mix(in srgb, var(--skin-accent) 16%, transparent);
  --color-token-list-active-selection-background: color-mix(in srgb, var(--skin-accent) 24%, transparent);
  --color-token-toolbar-hover-background: color-mix(in srgb, var(--skin-accent) 15%, transparent);
}

html.codex-skin[data-codex-skin-theme="${id}"] body {
  background:
    linear-gradient(90deg, color-mix(in srgb, var(--skin-panel) 94%, transparent) 0%, color-mix(in srgb, var(--skin-panel) 70%, transparent) 42%, color-mix(in srgb, var(--skin-bg) 22%, transparent) 100%),
    var(--dream-art) !important;
  background-size: cover !important;
  background-position: center right !important;
  background-attachment: fixed !important;
  color: var(--skin-text) !important;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", "Microsoft YaHei UI", system-ui, sans-serif !important;
}

html.codex-skin[data-codex-skin-theme="${id}"] aside.app-shell-left-panel {
  background: color-mix(in srgb, var(--skin-panel) 92%, transparent) !important;
  border-right: 1px solid var(--skin-line) !important;
  color: var(--skin-text) !important;
  backdrop-filter: blur(18px) saturate(1.15) !important;
}

html.codex-skin[data-codex-skin-theme="${id}"] main.main-surface {
  background:
    linear-gradient(90deg, color-mix(in srgb, var(--skin-panel) 88%, transparent), color-mix(in srgb, var(--skin-bg) 36%, transparent)),
    var(--dream-art) !important;
  background-size: cover !important;
  background-position: center right !important;
  border-left: 1px solid var(--skin-line) !important;
  overflow: hidden !important;
}

html.codex-skin[data-codex-skin-theme="${id}"] main.main-surface > header.app-header-tint,
html.codex-skin[data-codex-skin-theme="${id}"] .composer-surface-chrome,
html.codex-skin[data-codex-skin-theme="${id}"] textarea,
html.codex-skin[data-codex-skin-theme="${id}"] [contenteditable="true"] {
  background: color-mix(in srgb, var(--skin-panel) 88%, transparent) !important;
  border-color: var(--skin-line) !important;
  color: var(--skin-text) !important;
  backdrop-filter: blur(16px) saturate(1.1) !important;
}

html.codex-skin[data-codex-skin-theme="${id}"] button:hover,
html.codex-skin[data-codex-skin-theme="${id}"] [aria-current="page"] {
  background: color-mix(in srgb, var(--skin-accent) 16%, transparent) !important;
}

#codex-skin-chrome {
  position: fixed;
  z-index: 31;
  pointer-events: none;
  overflow: hidden;
}

#codex-skin-chrome .dream-brand,
#codex-skin-chrome .dream-signature {
  position: absolute;
  display: none;
  color: var(--skin-accent);
  text-shadow: 0 1px 12px color-mix(in srgb, var(--skin-panel) 60%, transparent);
}

#codex-skin-chrome.dream-home-shell .dream-brand {
  left: 24px;
  top: 8px;
  display: flex;
  align-items: center;
  gap: 10px;
}

#codex-skin-chrome.dream-home-shell .dream-signature {
  right: 88px;
  top: 10px;
  display: block;
  color: var(--skin-secondary);
  font-weight: 650;
}

#codex-skin-chrome .dream-brand b { display: block; font-size: 14px; letter-spacing: 0; }
#codex-skin-chrome .dream-brand small { display: block; color: var(--skin-muted); font-size: 10px; letter-spacing: 0; }
#codex-skin-chrome .dream-sparkles,
#codex-skin-chrome .dream-polaroid,
#codex-skin-chrome .dream-ribbon { display: none; }
`;
}

function manifestFor(id, displayName, detected, artPath, cssName, colors) {
  const dark = colors.background !== "#fff7fb" && colors.background !== "#ffffff";
  const source = detected.manifest;
  return {
    schemaVersion: 1,
    id,
    displayName,
    version: "1.0.0",
    css: cssName,
    art: artPath,
    copy: {
      brandTitle: displayName,
      brandSubtitle: source.brandSubtitle || "Imported Codex Skin",
      signature: source.quote || source.statusText || "imported theme",
      tagline: source.tagline || source.description || "外部主题已转换为 codex-skin 主题。",
      projectPrefix: source.projectPrefix || "选择项目 · ",
      projectLabel: source.projectLabel || "选择项目",
      ribbon: "✦",
    },
    baseTheme: {
      mode: source.appearance === "light" || source.appearance === "dark" ? source.appearance : dark ? "dark" : "light",
      codeTheme: "codex",
      accent: colors.accent,
      contrast: dark ? 82 : 70,
      ink: colors.text,
      surface: colors.background,
      opaqueWindows: true,
      semanticColors: {
        diffAdded: colors.secondary,
        diffRemoved: colors.highlight,
        skill: colors.accent,
      },
    },
    importSource: {
      type: detected.type,
      originalId: source.id || null,
      note: "Converted by scripts/import-external-theme.mjs. Review asset rights before redistribution.",
    },
  };
}

const options = parseArgs(process.argv.slice(2));
const source = await fs.realpath(options.source);
const detected = await detectTheme(source, options.mode);
const originalName = detected.manifest.name || detected.manifest.displayName || detected.manifest.id;
const id = slugify(options.id || detected.manifest.id || originalName);
if (!/^[a-z0-9][a-z0-9_-]*$/i.test(id)) throw new Error(`Invalid theme id: ${id}`);
const displayName = options.name || originalName || id;
const imagePath = await fs.realpath(imageFromExternalTheme(source, detected, options.preferAnimated));
const imageStat = await fs.stat(imagePath);
if (!imageStat.isFile() || imageStat.size < 1 || imageStat.size > 30 * 1024 * 1024) throw new Error("External theme image must be a non-empty file no larger than 30MB");

const themeDir = path.join(skillRoot, "themes");
const importedDir = path.join(skillRoot, "assets", "imported", id);
const imageName = path.basename(imagePath).replace(/[^a-z0-9._-]/gi, "-") || "art.png";
const artTarget = path.join(importedDir, imageName);
const manifestTarget = path.join(themeDir, `${id}.json`);
const cssTarget = path.join(themeDir, `${id}.css`);
if (!options.force) {
  for (const target of [artTarget, manifestTarget, cssTarget]) {
    if (await exists(target)) throw new Error(`Refusing to overwrite ${target}; use --force`);
  }
}

await fs.mkdir(importedDir, { recursive: true });
await fs.mkdir(themeDir, { recursive: true });
await fs.copyFile(imagePath, artTarget);
const colors = baseColorsFor(detected);
const artManifestPath = path.relative(themeDir, artTarget).split(path.sep).join("/");
const cssName = `${id}.css`;
await fs.writeFile(cssTarget, cssForTheme(id, colors), "utf8");
await fs.writeFile(manifestTarget, `${JSON.stringify(manifestFor(id, displayName, detected, artManifestPath, cssName, colors), null, 2)}\n`, "utf8");

console.log(JSON.stringify({
  imported: true,
  type: detected.type,
  id,
  displayName,
  manifest: manifestTarget,
  css: cssTarget,
  art: artTarget,
}, null, 2));
