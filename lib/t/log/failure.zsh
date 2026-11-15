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
# $color: color
# REPLY: null
# return: null
#
# example:
#  z.t._log.failure.add "red"
z.t._log.failure.add() {
  z.arg.named color $@ && local color=$REPLY

  z.t._state.current_idx "describe"
  local d_idx=$REPLY
  z.t._state.current_idx "context"
  local c_idx=$REPLY
  z.t._state.current_idx "it"
  local i_idx=$REPLY

  if z.int.is.not.zero $d_idx; then
    z.t._state.logs.context $d_idx
    z.str.color.red $REPLY

    z.t._state.logs.context.set index=$d_idx $REPLY
  fi

  if z.int.is.not.zero $c_idx; then
    z.t._state.logs.context $c_idx
    z.str.color.red $REPLY

    z.t._state.logs.context.set index=$c_idx $REPLY
  fi

  if z.int.is.not.zero $i_idx; then
    z.t._state.logs.context $i_idx
    z.str.color.red $REPLY

    z.t._state.logs.context.set index=$i_idx $REPLY
  fi
}

# process failure log
#
# $message: error message
# REPLY: null
# return: null
#
# example:
#  z.t._log.failure.handle "error message"
z.t._log.failure.handle() {
  z.arg.named message $@ && local error_message=$REPLY

  z.str.indent level=4 message=$error_message
  z.str.color.red $REPLY
  z.t._state.logs.add $REPLY

  z.t._state.compact
  local is_compact=$REPLY

  if z.is.true $is_compact; then
    z.t._state.current_it_failures.increment
  fi

  z.t._state.failures.increment
  z.t._log.failure.remember
  z.t._log.failure.add color=red
}
