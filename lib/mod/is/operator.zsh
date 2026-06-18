# check whether a z modifier is registered
#
# $1: mod name
# REPLY: null
# return: 0 if registered, otherwise 1
#
# example:
#  z.mod.is.registered git
z.mod.is.registered() {
  z.mod._store.ensure
  z.arg.first "$@"
  local mod_name=$REPLY

  z.is.true ${z_mod_names[$mod_name]:-false}
}
