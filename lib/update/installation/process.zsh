# replace an installation with a prepared directory and roll back a failed switch
#
# $dir: installation directory
# $prepared: prepared directory
# $backup: unused backup path
# REPLY: null
# return: 0|1
#
# example:
#  z.update.installation._replace dir=~/.z prepared=/tmp/next backup=/tmp/previous
z.update.installation._replace() {
  z.arg.named dir "$@"
  local dir=$REPLY

  z.arg.named prepared "$@"
  local prepared=$REPLY

  z.arg.named backup "$@"
  local backup=$REPLY

  z.is.null "$backup" && return 1
  z.dir.exists "$dir" || return 1
  z.dir.exists "$prepared" || return 1
  z.is.eq "$dir" "$prepared" && return 1
  z.file.exists "$backup" && return 1
  z.dir.exists "$backup" && return 1

  mv "$dir" "$backup" || return 1

  if ! mv "$prepared" "$dir"; then
    mv "$backup" "$dir" || z.io.error "restore the installation from $backup"
    return 1
  fi

  z.return
}

# reload the updated installation into the current shell
#
# $dir: installation directory
# $previous?: working directory before replacement (default: PWD)
# REPLY: null
# return: 0|1
#
# example:
#  z.update.installation._reload dir=~/.z previous=$PWD
z.update.installation._reload() {
  z.arg.named dir "$@"
  local dir=$REPLY
  z.file.exists "$dir/main.zsh" || return 1

  z.arg.named previous "$@" default="$PWD"
  local previous_dir=$REPLY

  if (( ${+functions[z.completion.cache._cancel]} )); then
    z.completion.cache._cancel || return 1
  fi

  if z.is.eq "$previous_dir" "$dir" || z.str.start_with "$previous_dir" "$dir/"; then
    z.str.remove.prefix "$previous_dir" "$dir"
    local relative_dir=$REPLY

    cd "$dir$relative_dir" 2>/dev/null || cd "$dir" || return 1
  fi

  export Z_ROOT="$dir"
  source "$dir/main.zsh" || return 1

  if (( ${+functions[z.completion.enable]} )); then
    z.completion.enable || return 1
  fi

  z.return
}
