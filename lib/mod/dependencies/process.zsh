# z modの依存関係を解決する
#
# $1: mod名
# REPLY: 依存するmod名に要求されたmod名を続けたもの
# return: 依存関係を解決できた場合は0、それ以外は1
#
# example:
#  z.mod.dependencies.resolve wtproxy
z.mod.dependencies.resolve() {
  z.mod._store.ensure
  z.arg.first "$@"
  local mod_name=$REPLY
  local -a resolved_mod_names=()
  local -A resolving_mod_name_map=()
  local -A resolved_mod_name_map=()

  z.mod.dependencies._resolve $mod_name || return 1
  REPLY=("${resolved_mod_names[@]}")
}

# 依存関係を再帰的に解決する
#
# $1: mod名
# REPLY: null
# return: 依存関係を解決できた場合は0、それ以外は1
#
# example:
#  z.mod.dependencies._resolve wtproxy
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
