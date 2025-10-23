# Logging functions for test framework
#
# REPLY: null
# return: null
#
# example:
#  z.t.log
z.t.log() {
  z.t.state.logs
}

# get failure records
#
# REPLY: failure records
# return: null
#
# example:
#  z.t.log.failure
z.t.log.failure() {
  z.t.state.failure_records
}

# remember failure record
#
# REPLY: null
# return: null
#
# example:
#  z.t.log.failure.remember
z.t.log.failure.remember() {
  local error_idx=${#z_t_logs[@]}

  z.t.state.current_idx "describe"
  local d_idx=$REPLY
  z.t.state.current_idx "context"
  local c_idx=$REPLY
  z.t.state.current_idx "it"
  local i_idx=$REPLY

  z.t.state.failure_records.add "$d_idx:$c_idx:$i_idx:$error_idx"
}

# add failure log with color
#
# $1: color
# REPLY: null
# return: null
#
# example:
#  z.t.log.failure.add "red"
z.t.log.failure.add() {
  local color=$1
  z.t.state.current_idx "describe"
  local d_idx=$REPLY
  z.t.state.current_idx "context"
  local c_idx=$REPLY
  z.t.state.current_idx "it"
  local i_idx=$REPLY

  if z.int.is_not_zero $d_idx; then
    z.t.state.logs.context $d_idx
    z.str.color.red $REPLY

    z.t.state.logs.context.set $d_idx $REPLY
  fi

  if z.int.is_not_zero $c_idx; then
    z.t.state.logs.context $c_idx
    z.str.color.red $REPLY

    z.t.state.logs.context.set $c_idx $REPLY
  fi

  if z.int.is_not_zero $i_idx; then
    z.t.state.logs.context $i_idx
    z.str.color.red $REPLY

    z.t.state.logs.context.set $i_idx $REPLY
  fi
}

# process failure log
#
# $1: error message
# REPLY: null
# return: null
#
# example:
#  z.t.log.failure.handle "error message"
z.t.log.failure.handle() {
  local error_message=$1

  z.str.indent 4 $error_message
  z.str.color.red $REPLY
  z.t.state.logs.add $REPLY

  z.t.state.failures.increment
  z.t.log.failure.remember
  z.t.log.failure.add "red"
}

# show all logs with summary
#
# REPLY: null
# return: null
#
# example:
#  z.t.log.show
z.t.log.show() {
  z.t.state.failures
  local failures=$REPLY

  z.guard; {
    z.t.state.logged
    z.is_true $REPLY && return 0
    z.t.state.failed_only
    z.is_true $REPLY && z.int.is_zero $failures && return 0
  }

  z.t.state.logged.set "true"

  z.t.log.show._summary $failures
  z.t.log._handle_all_log

  z.int.is_zero $failures && return 0
  z.t.state.all_log
  z.is_true $REPLY && return 0

  local prev_d_idx=""
  local prev_c_idx=""
  local prev_i_idx=""
  z.t.state.failure_records
  for record in $REPLY; do
    z.str.split $record ":"
    local -a indexes=($REPLY)
    local d_idx=$indexes[1]
    local c_idx=$indexes[2]
    local i_idx=$indexes[3]
    local e_idx=$indexes[4]

    if z.t.log._not_last_log $prev_d_idx $d_idx; then
      z.t.state.logs.context $d_idx
      z.int.is_not_zero $d_idx && z.io $REPLY
      prev_d_idx=$d_idx
      prev_c_idx=""
      prev_i_idx=""
    fi

    if z.t.log._not_last_log $prev_c_idx $c_idx; then
      z.t.state.logs.context $c_idx
      z.int.is_not_zero $c_idx && z.io $REPLY
      prev_c_idx=$c_idx
      prev_i_idx=""
    fi

    if z.t.log._not_last_log $prev_i_idx $i_idx; then
      z.t.state.logs.context $i_idx
      z.int.is_not_zero $i_idx && z.io $REPLY
      prev_i_idx=$i_idx
    fi

    z.t.state.logs.context $e_idx
    local error_log=$REPLY
    z.int.is_not_zero $e_idx && z.io $error_log
  done
}

# show summary of logs
# "<file_path> <num_tests> tests <num_failures> failures <num_pendings> pendings"
#
# $1: number of failures
# REPLY: null
# return: null
#
# example:
#  z.t.log.show._summary 3
z.t.log.show._summary() {
  local failures=$1

  z.t.state.file_path
  local display_path=${REPLY:r}
  local padded_path=$(printf "%-25s" $display_path)

  z.t.state.tests
  local tests=$REPLY
  z.t.state.pendings
  local pendings=$REPLY

  local padded_tests=$(printf "%3s" $tests)
  local padded_failures=$(printf "%2s" $failures)
  local padded_pendings=$(printf "%2s" $pendings)
  local message="$padded_path $padded_tests tests $padded_failures failures $padded_pendings pendings"

  z.int.is_zero $failures &&
    { z.str.color.green $message; } || { z.str.color.red $message; }
  z.io $REPLY
}

# handle all logs if all_log is true
#
# REPLY: null
# return: null
#
# example:
#  z.t.log._handle_all_log
z.t.log._handle_all_log() {
  z.t.state.all_log
  if z.is_true $REPLY; then
    z.t.state.logs

    for log in $REPLY; do
      z.io $log
    done
  fi
}

# check if current log is not the same as previous log
#
# $1: previous index
# $2: current index
# REPLY: null
# return: 0|1
#
# example:
#  if z.t.log._not_last_log $prev $current; then ... fi
z.t.log._not_last_log() {
  local prev=$1
  local current=$2

  z.not_eq $prev $current
}
