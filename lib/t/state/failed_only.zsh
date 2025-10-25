z_t_states[failed_only]="${Z_TEST_FAILED_ONLY:-false}"

# get the failed_only state
#
# REPLY: null
# return: true|false
#
# example:
#  z.t._state.failed_only  #=> "false"
z.t._state.failed_only() {
  z.return ${z_t_states[failed_only]}
}

# set the failed_only state
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.failed_only.set "true"
z.t._state.failed_only.set() {
  z_t_states[failed_only]=$1
}
