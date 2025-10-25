z_t_states[failures]=0

# get the number of failed tests
#
# REPLY: null
# return: number of failed tests
#
# example:
#  z.t._state.failures  #=> 2
z.t._state.failures() {
  z.return ${z_t_states[failures]}
}

# increment the number of failed tests by 1
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.failures.increment
z.t._state.failures.increment() {
  (( z_t_states[failures]++ ))
}
