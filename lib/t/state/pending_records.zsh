typeset z_t_pending_records=()

# get pending records
#
# REPLY: null
# return: pending records array
#
# example:
#  z.t._state.pending_records  #=> ("record1" "record2" ...)
z.t._state.pending_records() {
  z.return ${z_t_pending_records[@]}
}

# add a pending record
#
# $1: pending record
# REPLY: null
# return: null
#
# example:
#  z.t._state.pending_records.add "This is a pending record"
z.t._state.pending_records.add() {
  z_t_pending_records+=($1)
}
