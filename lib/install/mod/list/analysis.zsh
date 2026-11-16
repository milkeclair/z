# インストール済みmodと選択した配布内容を比較する
#
# $source: 配布対象modのディレクトリ
# $installed: 導入済みmodのディレクトリ
# REPLY: installed|update-available|not-installed
# return: 比較できた場合は0、それ以外は1
#
# example:
#  z.install.mod.list._status source=/tmp/source/git installed=~/.z/mod/git
z.install.mod.list._status() {
  z.arg.named source "$@" && local source_dir=$REPLY
  z.arg.named installed "$@" && local installed_dir=$REPLY

  if z.dir.not.exists "$installed_dir"; then
    REPLY=not-installed
    return
  fi

  if z.dir.not.exists "$source_dir"; then
    REPLY=installed
    return
  fi

  diff -qr -- "$source_dir" "$installed_dir" >/dev/null
  local result_code=$?

  case $result_code in
  0) REPLY=installed ;;
  1) REPLY=update-available ;;
  *) return 1 ;;
  esac
}
