#!/usr/bin/env bash
# ai-workflow 安装脚本
# 用法（在你的项目根目录执行）：
#   curl -fsSL https://raw.githubusercontent.com/dengshangli/ai-workflow/main/install.sh | bash
#
# 行为说明：
# - 规则正文放在 AI-WORKFLOW.md，复制到项目根目录
# - AGENTS.md / CLAUDE.md 只是对 AI-WORKFLOW.md 的引用；项目已有 AGENTS.md 时，
#   仅把一行引用追加到末尾（已包含则跳过），不动原有内容
# - 除 AGENTS.md 外的其他文件：项目没有则直接生成，已存在则直接覆盖

set -euo pipefail

REPO="dengshangli/ai-workflow"
BRANCH="main"
DEST="$(pwd)"

# 定位模板目录：本地仓库内直接用 templates/，否则从 GitHub 下载
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
TMP_DIR=""
# 仅当脚本确实位于本仓库内（install.sh 与 templates/ 并存）才用本地模板，
# 避免 curl | bash 时误把用户项目里的 templates/ 当作模板源
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/install.sh" ] && [ -f "$SCRIPT_DIR/templates/AGENTS.md" ]; then
  TEMPLATES="$SCRIPT_DIR/templates"
else
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  echo "正在从 GitHub 下载模板..."
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$TMP_DIR"
  TEMPLATES="$TMP_DIR/$(basename "$REPO")-$BRANCH/templates"
fi

if [ ! -d "$TEMPLATES" ]; then
  echo "错误：找不到模板目录 $TEMPLATES" >&2
  exit 1
fi

# 除 AGENTS.md 外的文件：不存在则新增，存在则直接覆盖
install_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"

  if [ ! -e "$dst" ]; then
    cp "$src" "$dst"
    echo "  新增        $dst"
    return
  fi
  if cmp -s "$src" "$dst"; then
    echo "  跳过(相同)  $dst"
    return
  fi
  cp "$src" "$dst"
  echo "  覆盖        $dst"
}

# AGENTS.md 专用：目标已存在时仅追加对 AI-WORKFLOW.md 的引用；已包含则跳过，保证可重复执行
append_file() {
  local src="$1" dst="$2"
  if [ ! -e "$dst" ]; then
    cp "$src" "$dst"
    echo "  新增        $dst"
    return
  fi
  if grep -qF '@AI-WORKFLOW.md' "$dst"; then
    echo "  跳过(已引用) $dst"
    return
  fi
  printf '\n' >> "$dst"
  cat "$src" >> "$dst"
  echo "  追加引用    $dst"
}

echo "安装 AI 工作流文件到：$DEST"
echo

while IFS= read -r src; do
  rel="${src#"$TEMPLATES"/}"
  if [ "$rel" = "AGENTS.md" ]; then
    append_file "$src" "$DEST/$rel"
  else
    install_file "$src" "$DEST/$rel"
  fi
done < <(find "$TEMPLATES" -type f ! -name '.DS_Store' | sort)

echo
echo "完成。"
