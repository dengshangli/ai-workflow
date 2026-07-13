# ai-workflow

一套可复用的 AI 编码工作流配置，一条命令即可注入到任意项目中。

包含三部分：

| 内容 | 说明 |
| --- | --- |
| `AGENTS.md` | 工作流规则的唯一来源（single source of truth）：技能库使用、开发流程（brainstorming → writing-plans → 实现 → 收尾）、代码审查、验证与排错规范等 |
| `CLAUDE.md` | 供 Claude Code 读取，内容仅一行 `@AGENTS.md`，引用上面的规则文件 |
| `.cursor/` | Cursor 专用配置：`rules/project-rules.mdc`（引用 AGENTS.md）和 `skills/figma-overlay-check`（Figma 叠图比对验收技能） |

## 安装

在**你自己项目的根目录**执行：

```bash
curl -fsSL https://raw.githubusercontent.com/dengshangli/ai-workflow/main/install.sh | bash
```

也可以克隆本仓库后本地执行：

```bash
git clone https://github.com/dengshangli/ai-workflow.git
cd 你的项目根目录
bash /path/to/ai-workflow/install.sh
```

## 冲突处理规则

安装脚本**永远不会覆盖你已有的文件**：

- 目标文件不存在 → 直接复制；
- 目标文件已存在且内容相同 → 跳过；
- `AGENTS.md` 已存在 → 模板内容**追加**到你项目的 `AGENTS.md` 末尾（如已包含相同内容则跳过，可重复执行）；
- 其他目标文件已存在且内容不同 → 原文件保持不动，新内容写入副本，如 `CLAUDE.copy.md`（副本也冲突时递增为 `CLAUDE.copy1.md`、`CLAUDE.copy2.md`…）。

`.cursor` 目录不会整体生成副本，而是**逐个文件**合并进你项目的 `.cursor/rules/`、`.cursor/skills/` 等目录，只有单个文件冲突时才为该文件生成副本。

安装完成后，如有 `*.copy.*` 副本，请手动对比合并，然后删除副本。

## 文件清单

```
templates/
├── AGENTS.md
├── CLAUDE.md
└── .cursor/
    ├── rules/
    │   └── project-rules.mdc
    └── skills/
        └── figma-overlay-check/
            ├── SKILL.md
            └── scripts/
                ├── crop.mjs
                └── pixel-diff.mjs
```

## 依赖说明

- `AGENTS.md` 中引用的技能（brainstorming、writing-plans、systematic-debugging 等）来自 [superpowers](https://github.com/obra/superpowers) 等技能库，MCP 服务（Figma、context7、Playwright）需在你的编辑器中自行配置。
- `figma-overlay-check` 技能的脚本依赖 Node.js 及 `pngjs`、`pixelmatch`（按需安装）。
