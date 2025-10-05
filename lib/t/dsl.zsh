local file_path=$1

local tests=0
local failures=0
local test_logs=()

local -A current_indexes=([describe]=0 [context]=0 [it]=0)
local -a failure_records=()

z.eq $z_mode "test" && {
  trap "z.t.teardown" EXIT
}

z.t.describe() {
  local description=$1

  z.str.indent 1 $description
  z.str.color.green $REPLY
  test_logs+=($REPLY)

  z.t._add_current_indexes "describe"
}

z.t.xdescribe() {
  local description=$1

  z.str.indent 1 $description
  z.str.color.yellow $REPLY
  test_logs+=($REPLY)

  z.t._add_current_indexes "describe"
}

z.t.context() {
  local context=$1

  z.str.indent 2 $context
  z.str.color.green $REPLY
  test_logs+=($REPLY)
  
  z.t._add_current_indexes "context"
}

z.t.xcontext() {
  local context=$1

  z.str.indent 2 $context
  z.str.color.yellow $REPLY
  test_logs+=($REPLY)

  z.t._add_current_indexes "context"
}

z.t.it() {
  REPLY=""

  local it=$1

  (( tests++ ))
  z.str.indent 3 $it
  z.str.color.green $REPLY
  test_logs+=($REPLY)

  z.t._add_current_indexes "it"
}

z.t.xit() {
  REPLY=""

  local it=$1

  (( tests++ ))
  z.str.indent 3 $it
  z.str.color.yellow $REPLY
  test_logs+=($REPLY)

  z.t._add_current_indexes "it"
}

z.t.expect() {
  local actual=$1
  local expect=$2

  if z.not_eq $expect $actual; then
    local expect_display=${(V)expect}
    local actual_display=${(V)actual}
    
    z.str.indent 4 "failed: expected [ $expect_display ] but got [ $actual_display ]"
    z.str.color.red $REPLY
    test_logs+=($REPLY)

    (( failures++ ))
    z.t._remember_failure
    z.t._colorize_failure "red"

    return 1
  else
    return 0
  fi
}

z.t.expect_status() {
  local actual=$?
  local expect=$1

  z.eq $expect "true" && expect=0
  z.eq $expect "false" && expect=1

  z.t.expect $actual $expect
}

z.t.expect_status.true() {
  z.t.expect_status "true"
}

z.t.expect_status.false() {
  z.t.expect_status "false"
}

z.t.expect_reply() {
  local expect=$1

  z.t.expect $REPLY $expect
}

z.t.expect_reply.null() {
  z.t.expect $REPLY ""
}

z.t.expect_reply.arr() {
  local -a expect=($@)
  local -a actual=($REPLY)

  local expect_str="${(j: :)expect}"
  local actual_str="${(j: :)actual}"

  z.t.expect "$actual_str" "$expect_str"
}

z.t.reset_functions() {
  z.is_not_null $1 && unfunction $1
  source ${z_main}
}

z.t.teardown() {
  z.t.reset_functions
  z.t._remove_tmp_dir
  z.t._log
}

# private

z.t._add_current_indexes() {
  local context=$1

  z.arr.count $test_logs

  case $context in
    "describe")
      current_indexes[describe]=$REPLY
      current_indexes[context]=0
      current_indexes[it]=0
      ;;
    "context")
      current_indexes[context]=$REPLY
      current_indexes[it]=0
      ;;
    "it")
      current_indexes[it]=$REPLY
      ;;
  esac
}

z.t._remember_failure() {
  z.arr.count $test_logs
  local error_idx=$REPLY

  local d_idx=${current_indexes[describe]}
  local c_idx=${current_indexes[context]}
  local i_idx=${current_indexes[it]}

  failure_records+=("$d_idx:$c_idx:$i_idx:$error_idx")
}

z.t._colorize_failure() {
  local color=$1
  local d_idx=${current_indexes[describe]}
  local c_idx=${current_indexes[context]}
  local i_idx=${current_indexes[it]}

  z.str.color.red ${test_logs[$d_idx]}
  test_logs[$d_idx]=$REPLY

  z.str.color.red ${test_logs[$c_idx]}
  test_logs[$c_idx]=$REPLY

  z.str.color.red ${test_logs[$i_idx]}
  test_logs[$i_idx]=$REPLY
}

z.t._remove_tmp_dir() {
  z.dir.is /tmp/z_test && rm -rf /tmp/z_test
}

z.t._log() {
  z.is_true $z_failed_only && z.int.is_zero $failures && return 0

  local display_path=${file_path:r}
  local padded_path=$(printf "%-25s" "$display_path")
  local padded_tests=$(printf "%3s" "$tests")
  local padded_failures=$(printf "%2s" "$failures")
  local message="$padded_path $padded_tests tests $padded_failures failures"

  z.int.is_zero $failures &&
    { z.str.color.green $message; } || { z.str.color.red $message; }
  z.io $REPLY

  if z.is_false $z_all_log; then
    for record in $failure_records; do
      z.str.split $record ":"
      local -a indexes=($REPLY)
      local d_idx=$indexes[1]
      local c_idx=$indexes[2]
      local i_idx=$indexes[3]
      local e_idx=$indexes[4]

      z.is_not_null $d_idx && z.int.is_zero $d_idx || z.io ${test_logs[$d_idx]}
      z.is_not_null $c_idx && z.int.is_zero $c_idx || z.io ${test_logs[$c_idx]}
      z.is_not_null $i_idx && z.int.is_zero $i_idx || z.io ${test_logs[$i_idx]}
      z.is_not_null $e_idx && z.int.is_zero $e_idx || z.io ${test_logs[$e_idx]}

      z.io ${test_logs[$e_idx]}
    done
  else
    for log in $test_logs; do
      z.io $log
    done
  fi
}
