# compare an installed mod with the selected distribution
#
# $source: distribution mod directory
# $installed: installed mod directory
# REPLY: installed|update-available|not-installed
# return: 0 if compared, otherwise 1
#
# example:
#  z.install.mod.list._status source=/tmp/source/git installed=~/.z/mod/git
z.install.mod.list._status() {
  z.arg.named source "$@" && local source_dir=$REPLY
  z.arg.named installed "$@" && local installed_dir=$REPLY

  if z.dir.not.exists "$installed_dir"; then
    z.return not-installed
    return
  fi

  if z.dir.not.exists "$source_dir"; then
    z.return installed
    return
  fi

  diff -qr -- "$source_dir" "$installed_dir" >/dev/null
  local result_code=$?

  case $result_code in
  0) z.return installed ;;
  1) z.return update-available ;;
  *) return 1 ;;
  esac
}
