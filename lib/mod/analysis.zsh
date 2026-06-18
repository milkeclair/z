# get direct dependencies of a z modifier
#
# $1: mod name
# REPLY: dependency mod names
# return: null
#
# example:
#  z.mod.dependencies wtproxy
z.mod.dependencies() {
  z.mod._store.ensure
  z.arg.first "$@"
  local mod_name=$REPLY

  z.return ${=z_mod_depends[$mod_name]}
}
