# 失敗と保留の記録を収集して整列する
#
# REPLY: 整列した記録の配列
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

  if z.is.false $failed_only; then
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
  z.int.is.zero $REPLY && { REPLY=(""); return 0; }

  local sorted_records=(${(o)all_records})
  REPLY=("${sorted_records[@]}")
}

# 整列済みの記録を表示する
#
# $@: 整列した記録
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
    if z.status.is.true; then
      prev_d_idx=$d_idx
      prev_c_idx=""
      prev_i_idx=""
    fi

    z.t._log.records.output_if_changed $c_idx $prev_c_idx
    if z.status.is.true; then
      prev_c_idx=$c_idx
      prev_i_idx=""
    fi

    z.t._log.records.output_if_changed $i_idx $prev_i_idx
    z.status.is.true && prev_i_idx=$i_idx

    if z.is.eq "$record_type" "failure" && z.is.not.null "$e_idx"; then
      z.t._state.logs.context $e_idx
      local error_log=$REPLY
      z.is.not.null $error_log && z.io $error_log
    fi
  done
}

# インデックスが変わった場合にログを出力する
#
# $1: 現在のインデックス
# $2: 前回のインデックス
# REPLY: null
# return: 0|1
#
# example:
#  z.t._log.records.output_if_changed $curr $prev
z.t._log.records.output_if_changed() {
  local curr_idx=$1
  local prev_idx=$2

  z.is.null $curr_idx && return 1
  z.int.is.zero $curr_idx && return 1

  if z.t._log.records.not_last_log $prev_idx $curr_idx; then
    z.t._state.logs.context $curr_idx
    z.is.not.null $REPLY && z.io $REPLY
    return 0
  fi

  return 1
}

# 現在のログが前回のログと異なるか確認する
#
# $1: 前回のインデックス
# $2: 現在のインデックス
# REPLY: null
# return: 0|1
#
# example:
#  if z.t._log.records.not_last_log $prev $current; then ... fi
z.t._log.records.not_last_log() {
  local prev=$1
  local current=$2

  z.is.not.eq $prev $current
}
