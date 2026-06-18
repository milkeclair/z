# resolve dependencies of a z modifier
#
# $1: mod name
# REPLY: dependency mod names followed by the requested mod name
# return: 0 if dependencies can be resolved, otherwise 1
#
# example:
#  z.mod.dependencies.resolve wt_proxy
z.mod.dependencies.resolve() {
  z.mod._store.ensure
  z.arg.first "$@"
  local mod_name=$REPLY
  local -a resolved_mod_names=()
  local -A resolving_mod_name_map=()
  local -A resolved_mod_name_map=()

  z.mod.dependencies._resolve $mod_name || return 1
  z.return ${resolved_mod_names[@]}
}

# resolve dependencies recursively
#
# $1: mod name
# REPLY: null
# return: 0 if dependencies can be resolved, otherwise 1
#
# example:
#  z.mod.dependencies._resolve wt_proxy
z.mod.dependencies._resolve() {
  z.arg.first "$@"
  local mod_name=$REPLY

  z.is.true ${resolved_mod_name_map[$mod_name]:-false} && return

  if z.is.true ${resolving_mod_name_map[$mod_name]:-false}; then
    z.io.error "cyclic mod dependency: $mod_name"
    return 1
  fi

  if ! z.mod.is.registered $mod_name; then
    z.io.error "mod is not registered: $mod_name"
    return 1
  fi

  resolving_mod_name_map[$mod_name]=true

  z.mod.dependencies $mod_name
  local -a dependencies=(${(@)REPLY})
  for dependency in $dependencies; do
    z.mod.dependencies._resolve $dependency || return 1
  done

  unset "resolving_mod_name_map[$mod_name]"
  resolved_mod_name_map[$mod_name]=true
  resolved_mod_names+=($mod_name)
}
