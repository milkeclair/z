# copy current mod data and replace selected mods in a prepared installation
#
# $source: source directory
# $current: current installation directory
# $dir: prepared installation directory
# $@: selected mod names after the named arguments
# REPLY: null
# return: 0|1
#
# example:
#  z.update.mod._copy source=/tmp/source current=~/.z dir=/tmp/update/next job
z.update.mod._copy() {
  z.arg.named source "$@"
  local source_dir=$REPLY

  z.arg.named current "$@"
  local current_dir=$REPLY

  z.arg.named dir "$@"
  local dir=$REPLY

  z.dir.exists "$source_dir" || return 1
  z.dir.exists "$current_dir" || return 1
  z.dir.exists "$dir" || return 1
  z.dir.exists "$dir/mod" && return 1

  z.arg.named.shift source "$@"
  z.arg.named.shift current "${(@)REPLY}"
  z.arg.named.shift dir "${(@)REPLY}"
  local selected=(${(@)REPLY})

  if z.dir.exists "$current_dir/mod"; then
    z.dir.make path="$dir/mod" || return 1

    cp -R "$current_dir/mod/." "$dir/mod/" || return 1
  fi

  for mod_name in "${selected[@]}"; do
    if z.dir.exists "$dir/mod/$mod_name"; then
      z.dir.remove path="$dir/mod/$mod_name" || return 1
    fi

    if z.dir.not.exists "$dir/mod"; then
      z.dir.make path="$dir/mod" || return 1
    fi

    cp -R "$source_dir/mod/$mod_name" "$dir/mod/$mod_name" || return 1
  done

  z.return
}
