z_t_states[logged]="false"

# check if any logs have been recorded
#
# REPLY: null
# return: 0|1
#
# example:
#  if z.t._state.logged; then ...; fi
z.t._state.logged() {
  z.return ${z_t_states[logged]}
}

# set the logged state
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t._state.logged.set "true"
z.t._state.logged.set() {
  z_t_states[logged]=$1
}
