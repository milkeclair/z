# ensure that z modifier stores are initialized
#
# REPLY: null
# return: null
#
# example:
#  z.mod._store.ensure
z.mod._store.ensure() {
  z.var.exists z_mod_names || typeset -gA z_mod_names
  z.var.exists z_mod_depends || typeset -gA z_mod_depends
  z.var.exists z_mod_current || typeset -g z_mod_current=""
}
