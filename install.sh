#!/usr/bin/env bash
# ai-workflow 安装脚本
# 用法（在你的项目根目录执行）：
#   curl -fsSL https://raw.githubusercontent.com/dengshangli/ai-workflow/main/install.sh | bash
#
# 行为说明：
# - AGENTS.md / CLAUDE.md 复制到项目根目录
# - 项目已有 AGENTS.md 时，把模板内容追加到项目的 AGENTS.md 末尾（已包含则跳过）
# - .cursor/ 下的文件逐个合并进项目的 .cursor/rules、.cursor/skills 等目录
# - 其他目标文件已存在且内容不同时，不覆盖，写入 xxx.copy.ext 副本
# - 目标文件已存在且内容相同时，跳过

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

# 生成不冲突的副本文件名：AGENTS.md -> AGENTS.copy.md -> AGENTS.copy1.md ...
copy_name() {
  local dir="$1" base="$2" n="$3" suffix
  [ "$n" -eq 0 ] && suffix="copy" || suffix="copy$n"
  if [[ "$base" == *.* ]]; then
    echo "$dir/${base%.*}.$suffix.${base##*.}"
  else
    echo "$dir/$base.$suffix"
  fi
}

install_file() {
  local src="$1" dst="$2"
  local dir base target n
  dir="$(dirname "$dst")"
  base="$(basename "$dst")"
  mkdir -p "$dir"

  if [ ! -e "$dst" ]; then
    cp "$src" "$dst"
    echo "  新增        $dst"
    return
  fi
  if cmp -s "$src" "$dst"; then
    echo "  跳过(相同)  $dst"
    return
  fi
  n=0
  target="$(copy_name "$dir" "$base" "$n")"
  while [ -e "$target" ]; do
    if cmp -s "$src" "$target"; then
      echo "  跳过(副本已存在) $target"
      return
    fi
    n=$((n + 1))
    target="$(copy_name "$dir" "$base" "$n")"
  done
  cp "$src" "$target"
  echo "  冲突→副本   $target  (原文件 $base 未改动)"
}

# AGENTS.md 专用：目标已存在时追加模板内容；已包含相同内容则跳过，保证可重复执行
append_file() {
  local src="$1" dst="$2"
  if [ ! -e "$dst" ]; then
    cp "$src" "$dst"
    echo "  新增        $dst"
    return
  fi
  if [[ "$(cat "$dst")" == *"$(cat "$src")"* ]]; then
    echo "  跳过(已包含) $dst"
    return
  fi
  printf '\n' >> "$dst"
  cat "$src" >> "$dst"
  echo "  追加        $dst"
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
done < <(find "$TEMPLATES" -type f | sort)

echo
echo "完成。如生成了 *.copy.* 副本，请手动对比合并后删除副本。"
