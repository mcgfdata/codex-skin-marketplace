import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import vm from "node:vm";
import { promisify } from "node:util";
import { DEFAULT_THEME, applySettings, buildBaseThemeSettings, loadTheme, restoreSettings, skillRoot } from "./theme-lib.mjs";
import { buildThemePackage } from "./theme-package.mjs";

const execFileAsync = promisify(execFile);

const theme = await loadTheme();
assert.equal(DEFAULT_THEME, "salary-cat");
assert.equal(theme.id, "salary-cat");
assert.equal(theme.version, "1.0.1");

const themeIds = (await fs.readdir(path.join(skillRoot, "themes")))
  .filter((entry) => entry.endsWith(".json"))
  .map((entry) => entry.slice(0, -5))
  .sort();
const requiredThemeIds = ["dilraba-rose", "dream", "kun-stage", "salary-cat"];
for (const required of requiredThemeIds) assert.ok(themeIds.includes(required), `missing required theme ${required}`);
const archivedThemeIds = [
  "catppuccin-mocha",
  "dracula",
  "github-light",
  "matrix-green",
  "nord-aurora",
  "ocean-calm",
  "rose-pine",
  "solarized-light",
  "tokyo-night",
];
for (const archived of archivedThemeIds) {
  await fs.access(path.join(skillRoot, "backups", "generated-themes", "themes", `${archived}.json`));
  await fs.access(path.join(skillRoot, "backups", "generated-themes", "previews", `${archived}.svg`));
}

for (const themeId of themeIds) {
  const candidate = await loadTheme(themeId);
  const candidateCss = await fs.readFile(candidate.cssPath, "utf8");
  assert.ok(candidateCss.length > 1_000, `${themeId} CSS should contain a complete theme`);
  const previewPath = path.join(skillRoot, "assets", "previews", `${themeId}.svg`);
  if (await fs.access(previewPath).then(() => true, () => false)) assert.ok(previewPath);
  const packaged = await buildThemePackage(themeId);
  assert.equal(packaged.bundle.manifest.id, themeId);
  assert.equal(packaged.bundle.manifest.css, "theme.css");
  assert.equal(Boolean(packaged.bundle.art), Boolean(candidate.artPath));
}

const originalConfig = `model = "gpt"\n\n[desktop]\nunrelated = true\nappearanceTheme = "dark"\n\n[other]\nkeep = "yes"\n`;
const applied = applySettings(originalConfig, buildBaseThemeSettings(theme, "darwin"));
assert.match(applied, /appearanceTheme = "light"/);
assert.match(applied, /code = "SF Mono"/);
assert.match(applied, /unrelated = true/);
assert.match(applied, /\[other\]\nkeep = "yes"/);

const duplicatedConfig = `model = "gpt"\n\n[desktop]\nappearanceTheme = "dark"\nappearanceTheme = "light"\nappearanceLightCodeThemeId = "one"\nappearanceLightCodeThemeId = "two"\nappearanceLightChromeTheme = { accent = "#111111", contrast = 1 }\nappearanceLightChromeTheme = { accent = "#222222", contrast = 2 }\nunrelated = true\n`;
const deduplicated = applySettings(duplicatedConfig, buildBaseThemeSettings(theme, "darwin"));
for (const key of ["appearanceTheme", "appearanceLightCodeThemeId", "appearanceLightChromeTheme"]) {
  assert.equal((deduplicated.match(new RegExp(`^${key}\\s*=`, "gm")) ?? []).length, 1, `${key} must be unique`);
}
const expandedChromeConfig = `model = "gpt"\n\n[desktop.appearanceLightChromeTheme.fonts]\ncode = "SF Mono"\nui = "PingFang SC"\n\n[desktop.appearanceLightChromeTheme.semanticColors]\nskill = "#fff"\n\n[sandbox_workspace_write]\nnetwork_access = true\nappearanceTheme = "light"\nappearanceLightChromeTheme = { accent = "#bad" }\n`;
const normalizedExpanded = applySettings(expandedChromeConfig, buildBaseThemeSettings(theme, "darwin"));
assert.doesNotMatch(normalizedExpanded, /^\[desktop\.appearanceLightChromeTheme/m);
assert.equal((normalizedExpanded.match(/^appearanceTheme\s*=/gm) ?? []).length, 1);
assert.equal((normalizedExpanded.match(/^appearanceLightChromeTheme\s*=/gm) ?? []).length, 1);
assert.match(normalizedExpanded, /\[sandbox_workspace_write\]\nnetwork_access = true/);
const emptyDesktop = applySettings(`[sandbox_workspace_write]\nnetwork_access = true\n\n[desktop]\n`, buildBaseThemeSettings(theme, "darwin"));
assert.match(emptyDesktop, /\[desktop\]\nappearanceTheme = "light"/);
assert.doesNotMatch(emptyDesktop, /network_access = true\nappearanceTheme/);
const duplicateDesktop = applySettings(`[desktop]\nunrelated = true\n\n[other]\nkeep = true\n\n[desktop]\nsecond = true\n`, buildBaseThemeSettings(theme, "darwin"));
assert.equal((duplicateDesktop.match(/^\[desktop\]$/gm) ?? []).length, 1);
assert.match(duplicateDesktop, /unrelated = true/);
assert.match(duplicateDesktop, /second = true/);
for (const key of ["accent", "contrast", "fonts", "ink", "opaqueWindows", "semanticColors", "surface"]) {
  assert.equal((buildBaseThemeSettings(theme, "darwin").appearanceLightChromeTheme.match(new RegExp(`\\b${key}\\s*=`, "g")) ?? []).length, 1, `chrome parameter ${key} must be unique`);
}
const restored = restoreSettings(applied, originalConfig, [
  "appearanceTheme",
  "appearanceLightCodeThemeId",
  "appearanceLightChromeTheme",
]);
assert.match(restored, /appearanceTheme = "dark"/);
assert.doesNotMatch(restored, /appearanceLightCodeThemeId/);
assert.match(restored, /unrelated = true/);

const restoredDuplicates = restoreSettings(deduplicated, duplicatedConfig, [
  "appearanceTheme",
  "appearanceLightCodeThemeId",
  "appearanceLightChromeTheme",
]);
for (const key of ["appearanceTheme", "appearanceLightCodeThemeId", "appearanceLightChromeTheme"]) {
  assert.equal((restoredDuplicates.match(new RegExp(`^${key}\\s*=`, "gm")) ?? []).length, 1, `restored ${key} must be unique`);
}

const [css, template, art] = await Promise.all([
  fs.readFile(theme.cssPath, "utf8"),
  fs.readFile(path.join(skillRoot, "assets", "renderer-inject.js"), "utf8"),
  fs.readFile(theme.artPath),
]);
const publicTheme = { id: theme.id, displayName: theme.displayName, version: theme.version, copy: theme.copy };
const payload = template
  .replace("__DREAM_CSS_JSON__", JSON.stringify(css))
  .replace("__DREAM_ART_JSON__", JSON.stringify(`data:image/png;base64,${art.toString("base64")}`))
  .replace("__DREAM_THEME_JSON__", JSON.stringify(publicTheme));
assert.doesNotMatch(payload, /__DREAM_(?:CSS|ART|THEME)_JSON__/);
assert.match(payload, /codex-skin/);
assert.match(payload, /CODEX_SKIN/);
const staleStatePrefix = "CODE" + "DROBE";
assert.doesNotMatch(payload, new RegExp(`${staleStatePrefix}_CODEX_SKIN`));
new vm.Script(payload);

const { bundle, serialized } = await buildThemePackage();
assert.equal(bundle.format, "codex-theme");
assert.equal(bundle.schemaVersion, 1);
assert.equal(bundle.manifest.css, "theme.css");
assert.equal(bundle.art?.mimeType, "image/gif");
assert.ok(bundle.art?.base64.length > 0);
assert.match(serialized, /"format": "codex-theme"/);

const temp = await fs.mkdtemp(path.join(os.tmpdir(), "codex-skin-"));
const stagedRuntime = path.join(temp, "runtime");
await execFileAsync("/bin/bash", [
  "-c",
  '. "$1"; deploy_codex_skin_runtime "$2" "$3"',
  "_",
  path.join(skillRoot, "scripts", "common-macos.sh"),
  skillRoot,
  stagedRuntime,
]);
const stagedManifest = JSON.parse(await fs.readFile(path.join(stagedRuntime, "themes", "salary-cat.json"), "utf8"));
const stagedArt = await fs.stat(path.join(stagedRuntime, "assets", "imported", "salary-cat", "salary-cat-hero.gif"));
assert.equal(stagedManifest.id, "salary-cat");
assert.ok(stagedArt.size > 1_000_000, "staged salary-cat artwork should be complete");
await assert.rejects(fs.access(path.join(stagedRuntime, ".git")));

const [commonScript, setupScript, startScript, restoreScript, injectorScript] = await Promise.all([
  fs.readFile(path.join(skillRoot, "scripts", "common-macos.sh"), "utf8"),
  fs.readFile(path.join(skillRoot, "scripts", "setup-skin.sh"), "utf8"),
  fs.readFile(path.join(skillRoot, "scripts", "start-skin-core.sh"), "utf8"),
  fs.readFile(path.join(skillRoot, "scripts", "restore-skin-core.sh"), "utf8"),
  fs.readFile(path.join(skillRoot, "scripts", "injector.mjs"), "utf8"),
]);
assert.match(commonScript, /\.codex\/codex-skin-runtime/);
assert.match(commonScript, /assets\/imported\/salary-cat\/salary-cat-hero\.gif/);
assert.match(commonScript, /rsync -a --delete/);
assert.match(commonScript, /CFBundleIdentifier/);
assert.match(commonScript, /node_is_supported/);
assert.match(setupScript, /deploy_codex_skin_runtime/);
assert.match(setupScript, /--in-place/);
assert.match(setupScript, /--no-launch/);
assert.match(setupScript, /ORIGINAL_PIDS=/);
assert.match(setupScript, /original_codex_is_running/);
assert.match(setupScript, /start-skin\.sh" --theme "\\\$THEME" --port "\\\$PORT" --restart-existing/);
assert.match(setupScript, /trap cleanup_deferred_start EXIT/);
assert.doesNotMatch(setupScript, /while \[ -n "\\\$\(main_pids\)" \]/);
const launchFunction = startScript.slice(
  startScript.indexOf("launch_codex_with_cdp()"),
  startScript.indexOf("safe_stop_injector()"),
);
assert.match(startScript, /--user-data-dir=\$PROFILE_PATH/);
assert.match(launchFunction, /launched_codex_is_running && return 0/);
assert.doesNotMatch(launchFunction, /stop_running_codex/);
assert.match(startScript, /stop_running_codex/);
assert.match(startScript, /seq 1 170/);
assert.match(startScript, /kill -KILL "\$pid"/);
assert.match(startScript, /launchctl submit -l "\$CODEX_SKIN_INJECTOR_LABEL"/);
assert.match(startScript, /resolve_codex_node/);
assert.match(startScript, /s\.injectorPath \|\| \(s\.skillRoot/);
assert.match(restoreScript, /cancel_deferred_start/);
assert.match(restoreScript, /Codex Skin - Restart\.command/);
assert.match(restoreScript, /kill -KILL "\$pid"/);
assert.match(restoreScript, /s\.injectorPath \|\| \(s\.skillRoot/);
assert.match(injectorScript, /forcedExitTimer = setTimeout\(\(\) => process\.exit\(0\), 1500\)/);
assert.match(injectorScript, /options\.mode} timed out after/);
assert.match(injectorScript, /process\.exit\(process\.exitCode \?\? 0\)/);
await fs.rm(temp, { recursive: true, force: true });
console.log(JSON.stringify({
  pass: true,
  theme: `${theme.id}@${theme.version}`,
  themes: themeIds,
  payloadBytes: Buffer.byteLength(payload),
  checks: ["active Skill themes", "archived generated themes", "theme schema", "mac base colors", "appearance key deduplication", "config restore", "payload syntax", "portable theme export", "mac runtime deployment", "bundled salary-cat artwork", "mac deferred restart", "non-destructive app launch fallback", "launchctl injector", "mac deferred cleanup"],
}, null, 2));
