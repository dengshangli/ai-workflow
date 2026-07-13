# ai-workflow

一套可复用的 AI 编码工作流配置，一条命令即可注入到任意项目中。

包含三部分：

| 内容 | 说明 |
| --- | --- |
| `AI-WORKFLOW.md` | 工作流规则的唯一来源（single source of truth）：技能库使用、开发流程（brainstorming → writing-plans → 实现 → 收尾）、代码审查、验证与排错规范等 |
| `AGENTS.md` | 内容仅一行引用 `@AI-WORKFLOW.md`；如果你的项目已有 AGENTS.md，只会把这行引用追加到末尾，不动原有内容 |
| `CLAUDE.md` | 供 Claude Code 读取，内容仅一行 `@AGENTS.md`，间接引用上面的规则文件 |
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

## 安装规则

- `AGENTS.md` 已存在 → 只把一行 `@AI-WORKFLOW.md` 引用**追加**到你项目的 `AGENTS.md` 末尾（已有该引用则跳过，可重复执行）；不存在则直接生成。
- 其他文件（含 `.cursor/` 下的文件，逐个处理）→ 不存在则直接生成，已存在则**直接覆盖**（内容相同时跳过）。

## 文件清单

```
templates/
├── AI-WORKFLOW.md
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

- `AI-WORKFLOW.md` 中引用的技能（brainstorming、writing-plans、systematic-debugging 等）来自 [superpowers](https://github.com/obra/superpowers) 等技能库，MCP 服务（Figma、context7、Playwright）需在你的编辑器中自行配置。
- `figma-overlay-check` 技能的脚本依赖 Node.js 及 `pngjs`、`pixelmatch`（按需安装）。
