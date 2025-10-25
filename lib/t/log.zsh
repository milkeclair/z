# Logging functions for test framework
#
# REPLY: null
# return: null
#
# example:
#  z.t._log
z.t._log() {
  z.t._state.logs
}

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
    z.t._log.handle_all_log

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
  z.dir.is $count_dir || return 0

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
  z.dir.is $compact_dir || return 0

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

  z.t._log.collect_records
  local -a sorted_records=($REPLY)

  z.arr.count $sorted_records
  z.int.is_zero $REPLY && return 0

  z.t._log.display_records ${sorted_records[@]}
}

# collect and sort failure and pending records
#
# REPLY: sorted records array
# return: null
#
# example:
#  z.t._log.collect_records
z.t._log.collect_records() {
  z.t._state.failed_only
  local failed_only=$REPLY

  local -a all_records=()

  z.t._state.failure_records
  local -a failure_records=($REPLY)
  for record in ${failure_records[@]}; do
    z.str.split $record ":"
    local -a parts=($REPLY)
    local d_idx=$parts[1]
    local c_idx=$parts[2]
    local i_idx=$parts[3]
    local e_idx=$parts[4]
    local sort_key=$(printf "%03d:%03d:%03d" $d_idx $c_idx $i_idx)
    local suffix="failure:$d_idx:$c_idx:$i_idx:$e_idx"
    local full_record="${sort_key}:${suffix}"
    all_records+=($full_record)
  done

  if z.is_false $failed_only; then
    z.t._state.pending_records
    local -a pending_records=($REPLY)
    for record in ${pending_records[@]}; do
      z.str.split $record ":"
      local -a parts=($REPLY)
      local d_idx=$parts[1]
      local c_idx=$parts[2]
      local i_idx=$parts[3]
      local sort_key=$(printf "%03d:%03d:%03d" $d_idx $c_idx $i_idx)
      local suffix="pending:$d_idx:$c_idx:$i_idx"
      local full_record="${sort_key}:${suffix}"
      all_records+=($full_record)
    done
  fi

  z.arr.count $all_records
  z.int.is_zero $REPLY && { z.return ""; return 0; }

  local -a sorted_records=(${(o)all_records})
  z.return ${sorted_records[@]}
}

# display sorted records
#
# $@: sorted records
# REPLY: null
# return: null
#
# example:
#  z.t._log.display_records ${records[@]}
z.t._log.display_records() {
  local -a sorted_records=($@)

  local prev_d_idx=""
  local prev_c_idx=""
  local prev_i_idx=""

  for record in ${sorted_records[@]}; do
    z.str.split $record ":"
    local -a parts=($REPLY)
    local record_type=$parts[4]
    local d_idx=$parts[5]
    local c_idx=$parts[6]
    local i_idx=$parts[7]
    local e_idx=$parts[8]

    z.t._log.output_if_changed $d_idx $prev_d_idx
    if [ $? -eq 0 ]; then
      prev_d_idx=$d_idx
      prev_c_idx=""
      prev_i_idx=""
    fi

    z.t._log.output_if_changed $c_idx $prev_c_idx
    if [ $? -eq 0 ]; then
      prev_c_idx=$c_idx
      prev_i_idx=""
    fi

    z.t._log.output_if_changed $i_idx $prev_i_idx
    [ $? -eq 0 ] && prev_i_idx=$i_idx

    if [ "$record_type" = "failure" ] && [ -n "$e_idx" ]; then
      z.t._state.logs.context $e_idx
      local error_log=$REPLY
      z.is_not_null $error_log && z.io $error_log
    fi
  done
}

# output log if index has changed
#
# $1: current index
# $2: previous index
# REPLY: null
# return: 0|1
#
# example:
#  z.t._log.output_if_changed $curr $prev
z.t._log.output_if_changed() {
  local curr_idx=$1
  local prev_idx=$2

  z.is_null $curr_idx && return 1
  z.int.is_zero $curr_idx && return 1

  if z.t._log.not_last_log $prev_idx $curr_idx; then
    z.t._state.logs.context $curr_idx
    z.is_not_null $REPLY && z.io $REPLY
    return 0
  fi

  return 1
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
#  z.t._log.handle_all_log
z.t._log.handle_all_log() {
  z.t._state.all_log
  if z.is_true $REPLY; then
    z.t._state.logs

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
#  if z.t._log.not_last_log $prev $current; then ... fi
z.t._log.not_last_log() {
  local prev=$1
  local current=$2

  z.not_eq $prev $current
}

# output green dot for successful test
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.success
z.t._log.dot.success() {
  z.t._log.dot.output "."
}

# output red dot for failed test
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.failure
z.t._log.dot.failure() {
  z.t._log.dot.output "F"
}

# output yellow dot for pending test
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.pending
z.t._log.dot.pending() {
  z.t._log.dot.output "*"
}

# internal: output colored dot with line wrapping
#
# $1: dot character (. F *)
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.output "F"
z.t._log.dot.output() {
  local char=$1
  local count_file="${Z_TEST_COMPACT_DIR}/.dot_count"
  local count=0

  z.file.is $count_file && count=$(cat $count_file)

  local terminal_width=${COLUMNS:-80}
  local width=80
  z.int.lt $terminal_width 80 && width=$terminal_width

  if z.int.eq $((count % width)) 0 && z.int.gt $count 0; then
    z.io.line
  fi

  case $char in
    "F") z.str.color.red $char ;;
    "*") z.str.color.yellow $char ;;
    *) z.str.color.green $char ;;
  esac

  printf "%s" $REPLY
  echo $((count + 1)) > $count_file
}

