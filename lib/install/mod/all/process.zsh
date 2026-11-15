# confirm installation or replacement of every distribution mod
#
# $dir: installed mod directory
# REPLY: null
# return: 0 for y/Y, otherwise 1
#
# example:
#  z.install.mod.all._confirm dir=~/.z/mod
z.install.mod.all._confirm() {
  z.arg.named dir "$@" && local dir=$REPLY

  z.io.oneline "Install or update all available mods in $dir? (y/n): "
  z.io.read || return 1
  local answer=$REPLY

  if z.is.eq "$answer" y || z.is.eq "$answer" Y; then
    z.return
    return 0
  fi

  z.return
  return 1
}

# prepare all distribution mods while preserving local-only mod data
#
# $source: distribution mod directory
# $current: installed mod directory, which may not exist
# $dir: new prepared mod directory
# REPLY: null
# return: 0|1
#
# example:
#  z.install.mod.all._prepare source=/tmp/source/mod current=~/.z/mod dir=/tmp/next
z.install.mod.all._prepare() {
  z.arg.named source "$@" && local source_dir=$REPLY
  z.arg.named current "$@" && local current_dir=$REPLY
  z.arg.named dir "$@" && local dir=$REPLY

  z.dir.exists "$source_dir" || return 1
  cp -R "$source_dir/." "$dir" || return 1

  if z.dir.exists "$current_dir"; then
    for entry in "$current_dir"/*(ND); do
      local name=${entry:t}

      if z.dir.exists "$entry" && z.dir.exists "$source_dir/$name"; then
        continue
      fi

      cp -R "$entry" "$dir/" || return 1
    done
  fi

  z.return
}

# switch prepared mods into place, restoring the old directory if switching fails
#
# $current: installed mod directory, which may not exist
# $prepared: prepared mod directory
# $backup: unused backup path
# REPLY: null
# return: 0|1
#
# example:
#  z.install.mod.all._replace current=~/.z/mod prepared=/tmp/next backup=/tmp/previous
z.install.mod.all._replace() {
  z.arg.named current "$@" && local current_dir=$REPLY
  z.arg.named prepared "$@" && local prepared=$REPLY
  z.arg.named backup "$@" && local backup=$REPLY

  z.dir.exists "$prepared" || return 1
  z.dir.exists "$backup" && return 1

  if z.dir.exists "$current_dir"; then
    mv "$current_dir" "$backup" || return 1
  fi

  if ! mv "$prepared" "$current_dir"; then
    if z.dir.exists "$backup"; then
      mv "$backup" "$current_dir" || z.io.error "restore mods from $backup"
    fi
    return 1
  fi

  z.return
}

# reconnect the working directory and load newly installed mods
# completion setup does not affect the reload result
#
# $dir: loaded z installation
# $previous?: working directory before switching (default: PWD)
# REPLY: null
# return: 0|1
#
# example:
#  z.install.mod.all._reload dir=~/.z previous=$PWD
z.install.mod.all._reload() {
  z.arg.named dir "$@" && local dir=$REPLY
  z.arg.named previous "$@" default="$PWD" && local previous_dir=$REPLY
  z.is.null "$dir" && return 1

  local mod_dir="$dir/mod"
  if z.is.eq "$previous_dir" "$mod_dir" || z.str.start_with "$previous_dir" "$mod_dir/"; then
    z.str.remove.prefix "$previous_dir" "$mod_dir"
    local relative_dir=$REPLY

    cd "$mod_dir$relative_dir" 2>/dev/null || cd "$dir" || return 1
  fi

  export Z_ROOT="$dir"
  source "$dir/main.zsh" || return 1

  if (( ${+functions[z.completion.enable]} )); then
    z.completion.enable
  fi

  z.return
}
