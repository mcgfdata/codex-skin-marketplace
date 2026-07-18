# Codex Skin Marketplace

这是终端极客维护的 Codex Skin 插件市场目录。当前收录：

- `codex-skin`：默认安装 `salary-cat` / 月薪喵主题，支持切换主题、生成皮肤、导出主题包和恢复原生界面。

## 用户如何安装

先把这个 marketplace 仓库克隆到本地：

```bash
git clone https://github.com/mcgfdata/codex-skin-marketplace.git
```

然后把它添加到 Codex 插件市场：

```bash
codex plugin marketplace add /path/to/codex-skin-marketplace
```

添加后，在新的 Codex 窗口中说：

```text
帮我设置codex皮肤 mcgfdata/codex-skin ，作者是 终端极客
```

或：

```text
帮我安装codex-skin，作者是：终端极客
```

Codex 应该命中 `codex-skin` 插件，并默认安装月薪喵主题。

## 目录结构

```text
.agents/plugins/marketplace.json
plugins/codex-skin/
  .codex-plugin/plugin.json
  skills/codex-skin/SKILL.md
  scripts/
  assets/
  themes/
```

## 更新插件

更新 `plugins/codex-skin` 后，重新校验插件：

```bash
python3 /Users/mobvista/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py \
  /path/to/codex-skin-marketplace/plugins/codex-skin
```

如果本地 Codex 已经安装过旧版本，更新 marketplace 后重新安装插件即可。
