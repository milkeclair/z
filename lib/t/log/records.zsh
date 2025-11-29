# collect and sort failure and pending records
#
# REPLY: sorted records array
# return: null
#
# example:
#  z.t._log.records.collect
z.t._log.records.collect() {
  z.t._state.failed_only
  local failed_only=$REPLY

  local all_records=()

  z.t._state.failure_records
  local failure_records=($REPLY)
  for record in ${failure_records[@]}; do
    z.str.split str=$record delimiter=:
    local parts=($REPLY)
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
    local pending_records=($REPLY)
    for record in ${pending_records[@]}; do
      z.str.split str=$record delimiter=:
      local parts=($REPLY)
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

  local sorted_records=(${(o)all_records})
  z.return ${sorted_records[@]}
}

# display sorted records
#
# $@: sorted records
# REPLY: null
# return: null
#
# example:
#  z.t._log.records.display ${records[@]}
z.t._log.records.display() {
  local sorted_records=($@)

  local prev_d_idx=""
  local prev_c_idx=""
  local prev_i_idx=""

  for record in ${sorted_records[@]}; do
    z.str.split str=$record delimiter=:
    local parts=($REPLY)
    local record_type=$parts[4]
    local d_idx=$parts[5]
    local c_idx=$parts[6]
    local i_idx=$parts[7]
    local e_idx=$parts[8]

    z.t._log.records.output_if_changed $d_idx $prev_d_idx
    if z.status.is_true; then
      prev_d_idx=$d_idx
      prev_c_idx=""
      prev_i_idx=""
    fi

    z.t._log.records.output_if_changed $c_idx $prev_c_idx
    if z.status.is_true; then
      prev_c_idx=$c_idx
      prev_i_idx=""
    fi

    z.t._log.records.output_if_changed $i_idx $prev_i_idx
    z.status.is_true && prev_i_idx=$i_idx

    if z.eq "$record_type" "failure" && z.is_not_null "$e_idx"; then
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
#  z.t._log.records.output_if_changed $curr $prev
z.t._log.records.output_if_changed() {
  local curr_idx=$1
  local prev_idx=$2

  z.is_null $curr_idx && return 1
  z.int.is_zero $curr_idx && return 1

  if z.t._log.records.not_last_log $prev_idx $curr_idx; then
    z.t._state.logs.context $curr_idx
    z.is_not_null $REPLY && z.io $REPLY
    return 0
  fi

  return 1
}

# check if current log is not the same as previous log
#
# $1: previous index
# $2: current index
# REPLY: null
# return: 0|1
#
# example:
#  if z.t._log.records.not_last_log $prev $current; then ... fi
z.t._log.records.not_last_log() {
  local prev=$1
  local current=$2

  z.not_eq $prev $current
}
