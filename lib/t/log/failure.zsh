# get failure records
#
# REPLY: failure records
# return: null
#
# example:
#  z.t._log.failure
z.t._log.failure() {
  z.t._state.failure_records
}

# remember failure record
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.failure.remember
z.t._log.failure.remember() {
  local error_idx=${#z_t_logs[@]}

  z.t._state.current_idx "describe"
  local d_idx=$REPLY
  z.t._state.current_idx "context"
  local c_idx=$REPLY
  z.t._state.current_idx "it"
  local i_idx=$REPLY

  z.t._state.failure_records.add "$d_idx:$c_idx:$i_idx:$error_idx"
}

# add failure log with color
#
# $1: color
# REPLY: null
# return: null
#
# example:
#  z.t._log.failure.add "red"
z.t._log.failure.add() {
  local color=$1
  z.t._state.current_idx "describe"
  local d_idx=$REPLY
  z.t._state.current_idx "context"
  local c_idx=$REPLY
  z.t._state.current_idx "it"
  local i_idx=$REPLY

  if z.int.is_not_zero $d_idx; then
    z.t._state.logs.context $d_idx
    z.str.color.red $REPLY

    z.t._state.logs.context.set $d_idx $REPLY
  fi

  if z.int.is_not_zero $c_idx; then
    z.t._state.logs.context $c_idx
    z.str.color.red $REPLY

    z.t._state.logs.context.set $c_idx $REPLY
  fi

  if z.int.is_not_zero $i_idx; then
    z.t._state.logs.context $i_idx
    z.str.color.red $REPLY

    z.t._state.logs.context.set $i_idx $REPLY
  fi
}

# process failure log
#
# $1: error message
# REPLY: null
# return: null
#
# example:
#  z.t._log.failure.handle "error message"
z.t._log.failure.handle() {
  local error_message=$1

  z.str.indent 4 $error_message
  z.str.color.red $REPLY
  z.t._state.logs.add $REPLY

  z.t._state.compact
  local is_compact=$REPLY

  if z.is_true $is_compact; then
    z.t._state.current_it_failures.increment
  fi

  z.t._state.failures.increment
  z.t._log.failure.remember
  z.t._log.failure.add "red"
}
