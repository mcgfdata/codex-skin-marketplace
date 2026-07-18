# Codex Skin

[English](README.en.md)

这是一个给 Codex 桌面版换皮肤的 Skill，也带有 Codex Plugin manifest。它可以应用现成皮肤、切换不同主题，也可以根据图片、配色或文字描述做新的皮肤包。

它的实现方式比较克制：通过本机的 Chromium DevTools Protocol 给 Codex 渲染层加样式，不改官方应用包，不替换可执行文件，也不动 `app.asar`。

作者：终端极客。新用户安装后，在新的 Codex 窗口里直接说：

```text
帮我安装codex-skin，作者是：终端极客
帮我设置codex皮肤 mcgfdata/codex-skin ，作者是 终端极客
帮我设置codex皮肤 mcgfdata/codex-skin，作者是：终端极客
```

Codex 应该命中 `$codex-skin`，并按默认 `salary-cat` 月薪喵主题执行安装。

也可以用这些说法，都会安装同一个默认主题：

```text
安装月薪喵 Codex 皮肤
设置 Codex 猫主题
安装 mcgfdata/codex-skin
帮我设置codex皮肤 mcgfdata/codex-skin ，作者是 终端极客
帮我设置codex皮肤 mcgfdata/codex-skin，作者是：终端极客
安装 salary-cat
```

本项目使用 Apache-2.0 许可。发布和转载时保留 `LICENSE` 和 `NOTICE` 文件。

## 能做什么

- 给 Codex 应用内置皮肤，并在不同主题之间切换。
- 按图片、风格描述或配色创建新皮肤。
- 导出 `.codex-theme` 主题包。
- 截图验证当前皮肤是否生效。
- 一键移除皮肤，恢复 Codex 原生界面。

当前内置皮肤：

- `salary-cat`（默认）
- `dilraba-rose`
- `dream`
- `kun-stage`

上一版生成的通用工程主题已移到 `backups/generated-themes/`，保留备份但不作为 README 主展示。

## 主题效果

| 主题 | 预览 |
| --- | --- |
| `salary-cat` | ![salary-cat 月薪喵主题效果](assets/imported/salary-cat/salary-cat-hero.gif) |
| `dilraba-rose` | ![dilraba-rose 主题效果](assets/previews/dilraba-rose.svg) |
| `dream` | ![dream 主题效果](assets/previews/dream.svg) |
| `kun-stage` | ![kun-stage 主题效果](assets/previews/kun-stage.svg) |

## 集成外部主题

本项目已支持导入同类开源皮肤项目的主题包：

- `kongxcer555/codex-skin-builder`：支持导入它生成的 `skin.json` 独立皮肤包。
- `Fei-Away/Codex-Dream-Skin`：支持导入 `theme.json + background` 预设目录。

导入 `codex-skin-builder` 生成包：

```bash
node scripts/import-external-theme.mjs \
  --source /absolute/path/to/generated-skin \
  --mode builder
```

导入 `Codex-Dream-Skin` 预设：

```bash
node scripts/import-external-theme.mjs \
  --source /absolute/path/to/Codex-Dream-Skin/macos/presets/preset-amber-dusk \
  --mode dream
```

导入后会生成：

- `themes/<theme-id>.json`
- `themes/<theme-id>.css`
- `assets/imported/<theme-id>/...`

然后按普通主题使用：

```bash
scripts/install-skin.sh --theme <theme-id>
scripts/restart-skin.sh --theme <theme-id>
```

注意：带 Codex 界面的效果截图不能直接当背景导入。应使用无 UI 的纯背景图，或导入外部仓库中已经整理好的 `theme.json + background` 目录。

## 环境要求

- 官方 Codex 桌面应用
- macOS 12+ 或 Windows 10/11
- Node.js 20+
- 本机 CDP 端口，只绑定 `127.0.0.1`

## 作为 Skill 使用

把本目录复制到 Codex 的 skills 目录：

```bash
mkdir -p ~/.codex/skills
cp -R /path/to/codex-skin ~/.codex/skills/codex-skin
```

然后在 Codex 里直接说。只要不指定主题，默认就是 `salary-cat` 月薪喵：

```text
帮我安装codex-skin，作者是：终端极客
帮我设置codex皮肤 mcgfdata/codex-skin ，作者是 终端极客
帮我设置codex皮肤 mcgfdata/codex-skin，作者是：终端极客
```

匹配规则写在 `SKILL.md` 和 `skills/codex-skin/SKILL.md` 的 frontmatter 里。插件市场或本地 Skill 索引时，重点识别这些词：

- `codex-skin`
- `帮我设置codex皮肤`
- `终端极客`
- `月薪喵`
- `salary-cat`
- `猫主题`
- `mcgfdata/codex-skin`

也可以说：

```text
Use $codex-skin 根据这张图做一个新的 Codex 皮肤。
Use $codex-skin 关闭皮肤，恢复原生界面。
```

## 作为 Plugin 发布

仓库根目录包含 `.codex-plugin/plugin.json`。发布到插件市场或被插件市场索引时，这个 manifest 会把当前目录声明为 `codex-skin` Skill。

用户从插件市场安装后，不需要手动选主题。只要不指定其他主题，默认就是月薪喵。

本地开发时可以用插件校验脚本检查：

```bash
python3 /Users/mobvista/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py /path/to/codex-skin
```

## 使用皮肤

最省事的方式是执行一次 `setup-skin`。它会安装皮肤配置，在桌面生成启动、重启、恢复三个入口，并尽量直接启动带图片注入的 Codex。

macOS：

```bash
cd /path/to/codex-skin
scripts/setup-skin.sh
```

Windows：

```powershell
cd C:\path\to\codex-skin
scripts\setup-skin.ps1
```

执行完成后，桌面会出现：

- `Codex Skin.command`：启动带皮肤的 Codex。
- `Codex Skin - Restart.command`：关闭当前 Codex，再用皮肤模式打开。
- `Codex Skin - Restore.command`：移除当前皮肤。

macOS 上如果 Codex 已经用普通方式打开，`setup-skin.sh` 会注册一个一次性后台任务。你只需要保存当前工作并 `Cmd+Q` 退出 Codex，它会自动重新打开带月薪喵图片的 Codex。之后日常使用时，双击 `Codex Skin.command` 即可。

如果不想等自动重启，也可以保存当前工作后双击 `Codex Skin - Restart.command`。

也可以不用桌面入口，直接运行：

```bash
scripts/restart-skin.sh
```

换皮肤只需要把主题名换掉：

```bash
scripts/install-skin.sh --theme kun-stage
scripts/restart-skin.sh --theme kun-stage
```

当前内置主题名：

- `salary-cat`（默认）
- `dilraba-rose`
- `dream`
- `kun-stage`

## 移除皮肤

如果只是想关闭当前运行中的皮肤注入，使用：

```bash
scripts/restore-skin.sh
```

这会停止皮肤注入并尝试清理当前 Codex 窗口里的装饰层，不会删除聊天、任务、登录状态。

如果想恢复得更干净，删除桌面快捷方式，并恢复安装前保存的基础主题配置：

```bash
scripts/restore-skin.sh --uninstall --restore-base-theme
```

Windows：

```powershell
scripts\restore-skin.ps1
scripts\restore-skin.ps1 -Uninstall -RestoreBaseTheme
```

如果恢复脚本提示没有备份，说明当前机器上没有找到安装前保存的基础主题配置。这种情况下可以先运行不带 `--restore-base-theme` 的恢复命令，只移除运行中的皮肤。

## 手动命令

如果不想生成桌面入口，可以手动安装和启动：

```bash
scripts/install-skin.sh
scripts/start-skin.sh
```

如果 Codex 已经打开，而且不是通过皮肤脚本启动的：

```bash
scripts/start-skin.sh --restart-existing
```

## 做一个新皮肤

先生成主题骨架：

```bash
node scripts/create-theme.mjs --id ocean-calm --name "Ocean Calm" --art /absolute/cover.png
```

主要改这两个文件：

- `themes/ocean-calm.json`
- `themes/ocean-calm.css`

应用并验证：

```bash
scripts/install-skin.sh --theme ocean-calm
scripts/start-skin.sh --theme ocean-calm
scripts/verify-skin.sh --theme ocean-calm --screenshot /absolute/ocean-calm.png
```

导出主题包：

```bash
node scripts/export-theme.mjs --theme ocean-calm --output /absolute/ocean-calm.codex-theme
```

## 开发

运行自测：

```bash
npm test
```

检查 npm 包内容：

```bash
npm run pack:check
```

## 安全边界

- CDP 只绑定到 `127.0.0.1`。
- 不要让多个皮肤控制器抢同一个端口。
- `.codex-theme` 当作不可信输入处理。
- 不要修改 `WindowsApps`、`/Applications/ChatGPT.app` 或 `app.asar`。

Codex 和 OpenAI 是各自所有者的商标。本项目是独立项目，不代表 OpenAI 官方。
