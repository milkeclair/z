z_t_states[all_log]="${Z_TEST_ALL_LOG:-false}"

# get the all_log state
#
# REPLY: null
# return: true|false
#
# example:
#  z.t._state.all_log  #=> "true"
z.t._state.all_log() {
  z.return ${z_t_states[all_log]}
}

# set the all_log state
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.all_log.set "true"
z.t._state.all_log.set() {
  z_t_states[all_log]=$1
}
