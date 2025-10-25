z_t_states[compact]="${Z_TEST_COMPACT:-false}"

# get the compact state
#
# REPLY: null
# return: true|false
#
# example:
#  z.t._state.compact  #=> "false"
z.t._state.compact() {
  z.return ${z_t_states[compact]}
}

# set the compact state
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.compact.set "true"
z.t._state.compact.set() {
  z_t_states[compact]=$1
}
