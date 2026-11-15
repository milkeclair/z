# resolve the dependency union of installed mods from the update snapshot
#
# $1: source directory
# $@: installed mod names after the source path
# REPLY: resolved mod names
# return: 0|1
z.update._mods() {
  local source_dir=$1
  shift
  z.mod.reset
  local recipe
  for recipe in "$source_dir"/mod/*/mod.zsh(N); do
    source "$recipe" || return 1
  done

  local -a mod_names=()
  local mod_name
  for mod_name in "$@"; do
    if z.mod.is.registered "$mod_name"; then
      z.mod.dependencies.resolve "$mod_name" || return 1
      mod_names+=("${(@)REPLY}")
    elif z.dir.exists "$source_dir/mod/$mod_name"; then
      mod_names+=("$mod_name")
    else
      z.io.error "mod does not exist in the update: $mod_name"
      return 1
    fi
  done
  z.arr.unique "${mod_names[@]}"
  mod_names=("${(@)REPLY}")
  for mod_name in "${mod_names[@]}"; do
    z.dir.exists "$source_dir/mod/$mod_name" || return 1
  done
  z.return "${mod_names[@]}"
}
