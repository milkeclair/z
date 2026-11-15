# update the installed core and installed mods from one branch snapshot
#
# REPLY: null
# return: 0|1
#
# example:
#  z.update
z.update() {
  local install_dir=${z_root:-${Z_ROOT:-}}
  if [[ $# != 0 || -z "$install_dir" || ! -f "$install_dir/main.zsh" || ! -d "$install_dir/lib" ]]; then
    z.io.error "z.update requires a loaded z installation and takes no arguments"
    return 1
  fi
  install_dir=${install_dir:A}
  if [[ -e "$install_dir/.git" || "$install_dir" == / || "$install_dir" == "$HOME" ]]; then
    z.io.error "use Git to update a checkout; z.update updates installed copies"
    return 1
  fi

  local previous_directory=${PWD:A}
  local -a installed_mod_names=("$install_dir"/mod/*(N/:t))
  z.io "Updating z and installed mods: ${(j:, :)installed_mod_names}"
  z.install._question_overwrite_install_dir || return 1
  ( z.update._replace "$install_dir" "${installed_mod_names[@]}" ) || return 1
  if (( ${+functions[z.completion.cache._cancel]} )); then
    z.completion.cache._cancel
  fi

  if [[ "$previous_directory" == "$install_dir" || "$previous_directory" == "$install_dir/"* ]]; then
    local relative_directory=${previous_directory#"$install_dir"}
    cd "$install_dir$relative_directory" 2>/dev/null || cd "$install_dir" || return 1
  fi
  export Z_ROOT="$install_dir"
  source "$install_dir/main.zsh" || return 1
  if (( ${+functions[z.completion.enable]} )); then
    z.completion.enable || return 1
  fi
  z.return
}

# stage core and the dependency union without changing the active installation
#
# $@: installed mod names
# REPLY: null
# return: 0|1
z.update._stage() {
  z.install._download_archive || return 1
  z.install._decompress_archive || return 1
  z.install.mod._source_mod_files || return 1

  local -a mod_names=()
  local mod_name
  for mod_name in "$@"; do
    z.install.mod._resolve_names || return 1
    mod_names+=("${(@)REPLY}")
  done
  z.arr.unique "${mod_names[@]}"
  mod_names=("${(@)REPLY}")
  for mod_name in "${mod_names[@]}"; do
    if [[ ! -d "$source_dir/mod/$mod_name" ]]; then
      z.io.error "mod does not exist in the update: $mod_name"
      return 1
    fi
  done

  z.install._preserve_mods || return 1
  install_dir="$temp_dir/next"
  z.install._copy_files || return 1
  local core_file
  for core_file in main.zsh install.zsh uninstall.zsh version.zsh help.zsh; do
    if [[ ! -f "$install_dir/$core_file" ]]; then
      z.io.error "core file is missing from the update: $core_file"
      return 1
    fi
  done
  install_dir="$temp_dir/next/mod"
  z.install.mod._install_names "${mod_names[@]}"
}

# prepare beside the installation, replace it, and restore it if switching fails
#
# $1: installation path
# $@: installed mod names
# REPLY: null
# return: 0|1
z.update._replace() {
  local target_dir=$1
  shift
  local install_dir=$target_dir
  local github_repo="milkeclair/z"
  local github_branch=${Z_INSTALL_BRANCH:-main}
  local source_dir=""
  local temp_dir
  temp_dir=$(mktemp -d "${target_dir:h}/.z-update.XXXXXX") || return 1

  {
    z.update._stage "$@" || return 1
    command mv "$target_dir" "$temp_dir/previous" || return 1
    if ! command mv "$temp_dir/next" "$target_dir"; then
      if ! command mv "$temp_dir/previous" "$target_dir"; then
        z.io.error "restore the installation from $temp_dir/previous"
      fi
      return 1
    fi
  } always {
    if [[ -e "$temp_dir/previous" && ! -e "$target_dir" ]]; then
      z.io.error "update recovery files were kept at $temp_dir"
    else
      z.dir.remove path="$temp_dir"
    fi
  }
}
