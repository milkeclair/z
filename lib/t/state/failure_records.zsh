typeset z_t_failure_records=()

# get failure records
#
# REPLY: null
# return: failure records array
#
# example:
#  z.t._state.failure_records  #=> ("record1" "record2" ...)
z.t._state.failure_records() {
  z.return ${z_t_failure_records[@]}
}

# add a failure record
#
# $1: failure record
# REPLY: null
# return: null
#
# example:
#  z.t._state.failure_records.add "This is a failure record"
z.t._state.failure_records.add() {
  z_t_failure_records+=($1)
}
