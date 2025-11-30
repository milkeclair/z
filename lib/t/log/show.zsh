# show all logs with summary
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.show
z.t._log.show() {
  z.t._log.show.save_counts

  z.t._log.show.should_skip && return 0

  z.t._state.logged.set "true"
  z.t._state.failures
  local failures=$REPLY

  z.t._state.compact
  if z.is_false $REPLY; then
    z.t._log.show.summary $failures
    z.t._log.show.all_log_if_enabled

    z.t._state.all_log
    z.is_true $REPLY && return 0

    z.t._log.show.failures_and_pendings
  else
    z.t._log.show.save_compact_results $failures
  fi
}

# internal: save test counts to file
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.show.save_counts
z.t._log.show.save_counts() {
  local count_dir=${Z_TEST_COUNT_DIR:-}
  z.dir.exists $count_dir || return 0

  z.t._state.tests
  local tests=$REPLY
  z.t._state.failures
  local failures=$REPLY
  z.t._state.pendings
  local pendings=$REPLY

  local count_idx=${Z_TEST_COUNT_IDX:-0}
  local count_file="$count_dir/${count_idx}_count.txt"
  echo "$tests $failures $pendings" > $count_file
}

# internal: save compact mode results to files
#
# $1: failures count
# REPLY: null
# return: null
#
# example:
#  z.t._log.show.save_compact_results 2
z.t._log.show.save_compact_results() {
  local failures=$1
  local compact_dir=${Z_TEST_COMPACT_DIR:-}
  z.dir.exists $compact_dir || return 0

  z.t._state.pendings
  local pendings=$REPLY

  z.int.is_zero $failures && z.int.is_zero $pendings && return 0

  local compact_idx=${Z_TEST_COMPACT_IDX:-0}
  local summary_file="$compact_dir/${compact_idx}_summary.txt"
  z.t._log.show.summary $failures > $summary_file

  if z.int.is_not_zero $failures; then
    local failure_file="$compact_dir/${compact_idx}_failure.txt"
    z.t._log.show.failures_and_pendings > $failure_file
  fi
}

# check if log should be skipped
#
# REPLY: null
# return: 0|1
#
# example:
#  z.t._log.show.should_skip && return 0
z.t._log.show.should_skip() {
  z.t._state.logged
  z.is_true $REPLY && return 0

  z.t._state.failed_only
  if z.is_true $REPLY; then
    z.t._state.failures
    z.int.is_zero $REPLY && return 0
  fi

  return 1
}

# show failure and pending records in order
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.show.failures_and_pendings
z.t._log.show.failures_and_pendings() {
  z.t._state.failures
  local failures=$REPLY
  z.t._state.pendings
  local pendings=$REPLY

  z.int.is_zero $failures && z.int.is_zero $pendings && return 0

  z.t._log.records.collect
  local sorted_records=($REPLY)

  z.arr.count $sorted_records
  z.int.is_zero $REPLY && return 0

  z.t._log.records.display ${sorted_records[@]}
}

# show summary of logs
# "<file_path> <num_tests> tests <num_failures> failures <num_pendings> pendings"
#
# $1: number of failures
# REPLY: null
# return: null
#
# example:
#  z.t._log.show.summary 3
z.t._log.show.summary() {
  local failures=$1

  z.t._state.file_path
  local display_path=${REPLY:r}
  local padded_path=$(printf "%-25s" $display_path)

  z.t._state.tests
  local tests=$REPLY
  z.t._state.pendings
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
#  z.t._log.show.all_log_if_enabled
z.t._log.show.all_log_if_enabled() {
  z.t._state.all_log
  if z.is_true $REPLY; then
    z.t._state.logs

    for log in $REPLY; do
      z.io $log
    done
  fi
}
