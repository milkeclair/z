# check whether a directory is an installed copy that can be updated
#
# $dir: installation directory
# REPLY: null
# return: 0|1
#
# example:
#  z.update.installation.is._valid dir=~/.z
z.update.installation.is._valid() {
  z.arg.named dir "$@" || return 1
  local dir=$REPLY

  z.is.null "$dir" && return 1
  z.is.eq "$dir" / && return 1
  z.is.eq "$dir" "$HOME" && return 1

  z.file.exists "$dir/main.zsh" || return 1
  z.dir.exists "$dir/lib" || return 1

  z.file.exists "$dir/.git" && return 1
  z.dir.exists "$dir/.git" && return 1

  return 0
}
