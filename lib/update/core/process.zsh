# 新しいインストール先へcoreの配布内容をコピーする
#
# $source: ソースディレクトリ
# $dir: 新しいインストール先ディレクトリ
# REPLY: null
# return: 0|1
#
# example:
#  # sourceに有効な配布内容があり、dirが未作成の場合
#  z.update.core._copy source=/tmp/source dir=/tmp/update/next
#  # return: 0
#  # 結果: /tmp/update/nextにmain.zsh、lib、testなどが配置される
z.update.core._copy() {
  z.arg.named source "$@"
  local source_dir=$REPLY
  z.dir.exists "$source_dir" || return 1

  z.arg.named dir "$@"
  local dir=$REPLY
  z.is.null "$dir" && return 1
  z.dir.exists "$dir" && return 1

  local core_files=(main.zsh install.zsh uninstall.zsh version.zsh help.zsh README.md)

  z.dir.make path="$dir" || return 1

  for entry in lib test "${core_files[@]}"; do
    cp -R "$source_dir/$entry" "$dir/$entry" || return 1
  done

  REPLY=""
}
