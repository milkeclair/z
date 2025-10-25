z_t_states[current_it_failures]=0

# get the current it failures count
#
# REPLY: null
# return: number of failures in current it
#
# example:
#  z.t._state.current_it_failures  #=> 0
z.t._state.current_it_failures() {
  z.return $z_t_states[current_it_failures]
}

# increment the current it failures count
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.current_it_failures.increment
z.t._state.current_it_failures.increment() {
  (( z_t_states[current_it_failures]++ ))
}

# reset the current it failures count
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.current_it_failures.reset
z.t._state.current_it_failures.reset() {
  z_t_states[current_it_failures]=0
}
