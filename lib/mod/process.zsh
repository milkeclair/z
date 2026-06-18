# define a z modifier
#
# $1: mod name
# REPLY: null
# return: null
#
# example:
#  z.mod git
z.mod() {
  z.mod._store.ensure
  z.arg.first "$@"
  local mod_name=$REPLY
  z.is.null "$mod_name" && return 1

  z_mod_current=$mod_name
  z_mod_names[$mod_name]=true
}

# add dependencies to the current z modifier
#
# $@: dependency mod names
# REPLY: null
# return: 0 if current mod exists, otherwise 1
#
# example:
#  z.mod wt_proxy; {
#    z.mod.depends git
#  }
z.mod.depends() {
  z.mod._store.ensure

  if z.is.null "$z_mod_current"; then
    z.io.error "current mod is not set"
    return 1
  fi

  z.mod.dependencies $z_mod_current
  local -a dependencies=(${(@)REPLY})
  dependencies+=("$@")
  z.arr.unique ${dependencies[@]}
  local -a unique_dependencies=(${(@)REPLY})

  z.arr.join ${unique_dependencies[@]}
  z_mod_depends[$z_mod_current]=$REPLY
}

# reset z modifier definitions
#
# REPLY: null
# return: null
#
# example:
#  z.mod.reset
z.mod.reset() {
  typeset -gA z_mod_names=()
  typeset -gA z_mod_depends=()
  typeset -g z_mod_current=""
}
