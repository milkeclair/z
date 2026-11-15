# copy the core distribution into a new installation directory
#
# $source: source directory
# $dir: new installation directory
# REPLY: null
# return: 0|1
#
# example:
#  z.update.core._copy source=/tmp/source dir=/tmp/update/next
z.update.core._copy() {
  z.arg.named source "$@" || return 1
  local source_dir=$REPLY
  z.arg.named dir "$@" || return 1
  local dir=$REPLY
  z.is.null "$dir" && return 1
  z.dir.exists "$dir" && return 1
  local core_files=(main.zsh install.zsh uninstall.zsh version.zsh help.zsh README.md)
  for directory in lib test; do
    z.dir.exists "$source_dir/$directory" || return 1
  done
  for core_file in "${core_files[@]}"; do
    z.file.exists "$source_dir/$core_file" || return 1
  done

  z.dir.make path="$dir" || return 1
  for entry in lib test "${core_files[@]}"; do
    cp -R "$source_dir/$entry" "$dir/$entry" || return 1
  done
  z.return
}
