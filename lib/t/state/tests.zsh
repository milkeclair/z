z_t_states[tests]=0

# get the number of tests executed
#
# REPLY: null
# return: number of tests
#
# example:
#  z.t._state.tests  #=> 10
z.t._state.tests() {
  z.return $z_t_states[tests]
}

# increment the number of tests executed by 1
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.tests.increment
z.t._state.tests.increment() {
  (( z_t_states[tests]++ ))
}
