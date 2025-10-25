z_t_states[pendings]=0

# get the number of pending tests
#
# REPLY: null
# return: number of pending tests
#
# example:
#  z.t._state.pendings  #=> 3
z.t._state.pendings() {
  z.return ${z_t_states[pendings]}
}

# increment the number of pending tests by 1
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.pendings.increment
z.t._state.pendings.increment() {
  (( z_t_states[pendings]++ ))
}
