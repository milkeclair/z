local z_test_file_path=$1

local z_test_tests=0
local z_test_failures=0
local z_test_logged="false"
local z_test_all_log="${Z_TEST_ALL_LOG:-false}"
local z_test_failed_only="${Z_TEST_FAILED_ONLY:-false}"

local -a z_test_logs=()
local -A z_test_current_idx=([describe]=0 [context]=0 [it]=0)
local -a z_test_failure_records=()

typeset -gA z_test_mock_calls=()
typeset -gA z_test_mock_originals=()
typeset -gA z_test_mock_saved_indexes=()
typeset -g z_test_mock_last_func=""

z.t.state() {
}

z.t.state.file_path() {
  z.return $z_test_file_path
}

z.t.state.tests() {
  z.return $z_test_tests
}

z.t.state.tests.increment() {
  (( z_test_tests++ ))
}

z.t.state.failures() {
  z.return $z_test_failures
}

z.t.state.failures.increment() {
  (( z_test_failures++ ))
}

z.t.state.mark_error() {
  local message=$1

  local error_flag_file="/tmp/z_test_error_$$"
  z.file.make_with_dir $error_flag_file
  echo $message >> $error_flag_file

  return 127
}

z.t.state.logged() {
  z.return $z_test_logged
}

z.t.state.logged.set() {
  z_test_logged=$1
}

z.t.state.all_log() {
  z.return $z_test_all_log
}

z.t.state.all_log.set() {
  z_test_all_log=$1
}

z.t.state.failed_only() {
  z.return $z_test_failed_only
}

z.t.state.failed_only.set() {
  z_test_failed_only=$1
}

z.t.state.logs() {
  z.return ${z_test_logs[@]}
}

z.t.state.logs.add() {
  z_test_logs+=($1)
}

z.t.state.logs.context() {
  local context=$1
  z.return ${z_test_logs[$context]}
}

z.t.state.logs.context.set() {
  local context=$1
  local value=$2

  local target_log=${z_test_logs[$context]}

  if z.is_not_null $target_log; then
    z_test_logs[$context]=$value
  fi
}

z.t.state.current_idx() {
  local context=$1
  z.return ${z_test_current_idx[$context]}
}

z.t.state.current_idx.set() {
  local context=$1
  local value=$2
  z_test_current_idx[$context]=$value
}

z.t.state.current_idx.add() {
  local context=$1
  z.arr.count $z_test_logs
  local idx=$REPLY

  case $context in
  "describe")
    z.t.state.current_idx.set "describe" $idx
    z.t.state.current_idx.set "context" 0
    z.t.state.current_idx.set "it" 0
    ;;
  "context")
    z.t.state.current_idx.set "context" $idx
    z.t.state.current_idx.set "it" 0
    ;;
  "it")
    z.t.state.current_idx.set "it" $idx
    ;;
  esac

  z.return $idx
}

z.t.state.failure_records() {
  z.return ${z_test_failure_records[@]}
}

z.t.state.failure_records.add() {
  z_test_failure_records+=($1)
}

z.t.state.mock_originals() {
  z.return ${(k)z_test_mock_originals[@]}
}

z.t.state.mock_originals.context() {
  z.return ${z_test_mock_originals[$1]}
}

z.t.state.mock_originals.add() {
  local func_name=$1
  local original_func=$2

  z_test_mock_originals[$func_name]=$original_func
}

z.t.state.mock_originals.unset() {
  unset "z_test_mock_originals[$1]" 2>/dev/null
}

z.t.state.mock_saved_indexes() {
  z.return ${z_test_mock_saved_indexes[@]}
}

z.t.state.mock_saved_indexes.context() {
  z.return ${z_test_mock_saved_indexes[$1]}
}

z.t.state.mock_saved_indexes.add() {
  local key=$1
  local value=$2
  z_test_mock_saved_indexes[$key]=$value
}
z.t.state.mock_saved_indexes.unset() {
  unset "z_test_mock_saved_indexes[$1]" 2>/dev/null
}

z.t.state.mock_calls() {
  z.return ${z_test_mock_calls[@]}
}

z.t.state.mock_calls.context() {
  z.return ${z_test_mock_calls[$1]}
}

z.t.state.mock_calls.add() {
  local func_name=$1 && shift
  local args=$@

  if z.is_not_null ${z_test_mock_calls[$func_name]}; then
    z_test_mock_calls[$func_name]="${z_test_mock_calls[$func_name]}:$args"
  else
    z_test_mock_calls[$func_name]=$args
  fi
}

z.t.state.mock_calls.set() {
  local func_name=$1
  local value=$2

  z_test_mock_calls[$func_name]=$value
}

z.t.state.mock_calls.unset() {
  unset "z_test_mock_calls[$1]" 2>/dev/null
}

z.t.state.mock_last_func() {
  z.return $z_test_mock_last_func
}

z.t.state.mock_last_func.set() {
  z_test_mock_last_func=$1
}
