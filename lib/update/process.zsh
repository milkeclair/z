# update the installed core and installed mods from one branch snapshot
#
# REPLY: null
# return: 0|1
#
# example:
#  z.update
z.update() {
  local install_dir=${z_root:-${Z_ROOT:-}}
  if z.int.is.not.zero $# || z.is.null "$install_dir" ||
      ! z.file.exists "$install_dir/main.zsh" || ! z.dir.exists "$install_dir/lib"; then
    z.io.error "z.update requires a loaded z installation and takes no arguments"
    return 1
  fi
  z.str.is.path_like "$install_dir" || install_dir="./$install_dir"
  z.path.real "$install_dir"
  install_dir=$REPLY
  if z.file.exists "$install_dir/.git" || z.dir.exists "$install_dir/.git" ||
      z.is.eq "$install_dir" / || z.is.eq "$install_dir" "$HOME"; then
    z.io.error "use Git to update a checkout; z.update updates installed copies"
    return 1
  fi

  z.path.real "$PWD"
  local previous_directory=$REPLY
  local -a installed_mod_names=("$install_dir"/mod/*(N/:t))
  z.arr.join "${installed_mod_names[@]}" delimiter=", "
  z.io "Updating z and installed mods: $REPLY"
  z.update._confirm "$install_dir" || return 1
  ( z.update._replace "$install_dir" "${installed_mod_names[@]}" ) || return 1
  if (( ${+functions[z.completion.cache._cancel]} )); then
    z.completion.cache._cancel
  fi

  if z.is.eq "$previous_directory" "$install_dir" || z.str.start_with "$previous_directory" "$install_dir/"; then
    z.str.remove.prefix "$previous_directory" "$install_dir"
    local relative_directory=$REPLY
    cd "$install_dir$relative_directory" 2>/dev/null || cd "$install_dir" || return 1
  fi
  export Z_ROOT="$install_dir"
  source "$install_dir/main.zsh" || return 1
  if (( ${+functions[z.completion.enable]} )); then
    z.completion.enable || return 1
  fi
  z.return
}

# confirm an update of the loaded installation
#
# $1: installation path
# REPLY: null
# return: 0|1
z.update._confirm() {
  z.io.oneline "Update $1 and its installed mods? (y/n): "
  z.io.read || return 1
  local response=$REPLY
  z.is.eq "$response" y || z.is.eq "$response" Y
}

# download and extract one branch archive
#
# $1: temporary directory
# $2: branch
# REPLY: extracted source directory
# return: 0|1
z.update._download() {
  local temp_dir=$1
  local branch=$2
  local archive_url="https://github.com/milkeclair/z/archive/refs/heads/$branch.tar.gz"
  command curl -fLsS "$archive_url" -o "$temp_dir/archive.tar.gz" || return 1
  z.dir.make path="$temp_dir/source" || return 1
  command tar -xzf "$temp_dir/archive.tar.gz" -C "$temp_dir/source" || return 1
  local -a source_dirs=("$temp_dir/source"/*(N/))
  if ! z.int.is.eq "${#source_dirs}" 1; then
    z.io.error "expected one source directory in the update archive"
    return 1
  fi
  z.return "$source_dirs[1]"
}

# stage core and selected mods without changing the active installation
#
# $1: source directory
# $2: active installation directory
# $3: staging directory
# $@: resolved mod names after the three paths
# REPLY: null
# return: 0|1
z.update._stage() {
  local source_dir=$1
  local target_dir=$2
  local staged_dir=$3
  shift 3
  local -a core_files=(main.zsh install.zsh uninstall.zsh version.zsh help.zsh README.md)
  local name
  for name in lib test; do
    z.dir.exists "$source_dir/$name" || return 1
  done
  for name in "${core_files[@]}"; do
    z.file.exists "$source_dir/$name" || return 1
  done

  z.dir.make path="$staged_dir" || return 1
  for name in lib test "${core_files[@]}"; do
    command cp -R "$source_dir/$name" "$staged_dir/$name" || return 1
  done
  if z.dir.exists "$target_dir/mod"; then
    z.dir.make path="$staged_dir/mod" || return 1
    command cp -R "$target_dir/mod/." "$staged_dir/mod/" || return 1
  fi
  for name in "$@"; do
    if z.dir.exists "$staged_dir/mod/$name"; then
      z.dir.remove path="$staged_dir/mod/$name" || return 1
    fi
    if z.dir.not.exists "$staged_dir/mod"; then
      z.dir.make path="$staged_dir/mod" || return 1
    fi
    command cp -R "$source_dir/mod/$name" "$staged_dir/mod/$name" || return 1
  done
}

# prepare beside the installation, replace it, and restore it if switching fails
#
# $1: installation path
# $@: installed mod names after the installation path
# REPLY: null
# return: 0|1
z.update._replace() {
  local target_dir=$1
  shift
  z.path.dir "$target_dir"
  local parent_dir=$REPLY
  local temp_dir
  temp_dir=$(mktemp -d "$parent_dir/.z-update.XXXXXX") || return 1

  {
    z.update._download "$temp_dir" "${Z_INSTALL_BRANCH:-main}" || return 1
    local source_dir=$REPLY
    z.update._mods "$source_dir" "$@" || return 1
    local -a mod_names=()
    z.is.not.null "$REPLY" && mod_names=("${(@)REPLY}")
    z.update._stage "$source_dir" "$target_dir" "$temp_dir/next" "${mod_names[@]}" || return 1
    command mv "$target_dir" "$temp_dir/previous" || return 1
    if ! command mv "$temp_dir/next" "$target_dir"; then
      if ! command mv "$temp_dir/previous" "$target_dir"; then
        z.io.error "restore the installation from $temp_dir/previous"
      fi
      return 1
    fi
  } always {
    if z.dir.exists "$temp_dir/previous" && z.dir.not.exists "$target_dir"; then
      z.io.error "update recovery files were kept at $temp_dir"
    else
      z.dir.remove path="$temp_dir"
    fi
  }
}
