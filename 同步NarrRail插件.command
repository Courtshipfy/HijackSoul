#!/bin/zsh

set -u

cd "$(dirname "$0")" || exit 1

SUBMODULE_PATH="third_party/NarrRail-Godot-Plugin"
PLUGIN_SOURCE="$SUBMODULE_PATH/narrrail"
PLUGIN_TARGET="hijacksoul/addons/narrrail"

echo "当前目录: $(pwd)"
echo

if ! command -v git >/dev/null 2>&1; then
  echo "错误: 没有找到 Git，请先安装 Git。"
  echo
  read "reply?按回车键关闭窗口..."
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "错误: 没有找到 rsync。"
  echo
  read "reply?按回车键关闭窗口..."
  exit 1
fi

echo "正在初始化并更新 NarrRail submodule..."
git submodule update --init --remote "$SUBMODULE_PATH"
update_status=$?
if [[ $update_status -ne 0 ]]; then
  echo
  echo "更新 NarrRail submodule 失败，请检查网络或仓库权限。"
  echo
  read "reply?按回车键关闭窗口..."
  exit $update_status
fi

if [[ ! -f "$PLUGIN_SOURCE/plugin.cfg" ]]; then
  echo
  echo "错误: 找不到插件源目录: $PLUGIN_SOURCE"
  echo "预期文件不存在: $PLUGIN_SOURCE/plugin.cfg"
  echo
  read "reply?按回车键关闭窗口..."
  exit 1
fi

mkdir -p "hijacksoul/addons"

echo
echo "正在同步插件到 $PLUGIN_TARGET ..."
rsync -a --delete \
  --exclude ".git" \
  --exclude ".godot" \
  --exclude ".DS_Store" \
  --exclude "Thumbs.db" \
  --exclude "Desktop.ini" \
  "$PLUGIN_SOURCE/" "$PLUGIN_TARGET/"
sync_status=$?

if [[ $sync_status -ne 0 ]]; then
  echo
  echo "同步失败，rsync 退出码: $sync_status"
  echo
  read "reply?按回车键关闭窗口..."
  exit $sync_status
fi

echo
echo "NarrRail 插件同步完成。当前 submodule 提交:"
git -C "$SUBMODULE_PATH" --no-pager log -1 --oneline
echo
echo "如果插件内容有变化，请提交 submodule 指针和 hijacksoul/addons/narrrail 下的文件变更。"
echo
read "reply?按回车键关闭窗口..."
