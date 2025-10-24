local z_t_file_path=$1

local z_t_tests=0
local z_t_failures=0
local z_t_pendings=0
local z_t_logged="false"
local z_t_all_log="${Z_TEST_ALL_LOG:-false}"
local z_t_failed_only="${Z_TEST_FAILED_ONLY:-false}"
local z_t_skip_describe="false"
local z_t_skip_context="false"
local z_t_skip_it="false"

local -a z_t_logs=()
local -A z_t_current_idx=([describe]=0 [context]=0 [it]=0)
local -a z_t_failure_records=()
local -a z_t_pending_records=()

typeset -gA z_t_mock_calls=()
typeset -gA z_t_mock_originals=()
typeset -gA z_t_mock_saved_indexes=()
typeset -g z_t_mock_last_func=""

# state management module
z.t.state() {
}

# get the test file path
#
# REPLY: null
# return: file path
#
# example:
#  z.t.state.file_path  #=> "/path/to/test_file.zsh"
z.t.state.file_path() {
  z.return $z_t_file_path
}

# get the number of tests executed
#
# REPLY: null
# return: number of tests
#
# example:
#  z.t.state.tests  #=> 10
z.t.state.tests() {
  z.return $z_t_tests
}

# increment the number of tests executed by 1
#
# REPLY: null
# return: null
#
# example:
#  z.t.state.tests.increment
z.t.state.tests.increment() {
  (( z_t_tests++ ))
}

# get the number of failed tests
#
# REPLY: null
# return: number of failed tests
#
# example:
#  z.t.state.failures  #=> 2
z.t.state.failures() {
  z.return $z_t_failures
}

# increment the number of failed tests by 1
#
# REPLY: null
# return: null
#
# example:
#  z.t.state.failures.increment
z.t.state.failures.increment() {
  (( z_t_failures++ ))
}

# get the number of pending tests
#
# REPLY: null
# return: number of pending tests
#
# example:
#  z.t.state.pendings  #=> 3
z.t.state.pendings() {
  z.return $z_t_pendings
}

# increment the number of pending tests by 1
#
# REPLY: null
# return: null
#
# example:
#  z.t.state.pendings.increment
z.t.state.pendings.increment() {
  (( z_t_pendings++ ))
}

# mark the test suite as having command not found error
#
# $1: error message
# REPLY: null
# return: 127(command not found)
#
# example:
#  z.t.state.mark_not_found_error "command not found: ls"
z.t.state.mark_not_found_error() {
  local message=$1

  local error_flag_file="/tmp/z_t_error_$$"
  z.file.make_with_dir $error_flag_file
  echo $message >> $error_flag_file

  return 127
}

# check if any logs have been recorded
#
# REPLY: null
# return: 0|1
#
# example:
#  if z.t.state.logged; then ...; fi
z.t.state.logged() {
  z.return $z_t_logged
}

# set the logged state
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t.state.logged.set "true"
z.t.state.logged.set() {
  z_t_logged=$1
}

# get the all_log state
#
# REPLY: null
# return: true|false
#
# example:
#  z.t.state.all_log  #=> "true"
z.t.state.all_log() {
  z.return $z_t_all_log
}

# set the all_log state
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t.state.all_log.set "true"
z.t.state.all_log.set() {
  z_t_all_log=$1
}

# get the failed_only state
#
# REPLY: null
# return: true|false
#
# example:
#  z.t.state.failed_only  #=> "false"
z.t.state.failed_only() {
  z.return $z_t_failed_only
}

# set the failed_only state
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t.state.failed_only.set "true"
z.t.state.failed_only.set() {
  z_t_failed_only=$1
}

# get the skip state for describe level
#
# REPLY: null
# return: true|false
#
# example:
#  z.t.state.skip.describe  #=> "false"
z.t.state.skip.describe() {
  z.return $z_t_skip_describe
}

# set the skip state for describe level
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t.state.skip.describe.set "true"
z.t.state.skip.describe.set() {
  z_t_skip_describe=$1
}

# get the skip state for context level
#
# REPLY: null
# return: true|false
#
# example:
#  z.t.state.skip.context  #=> "false"
z.t.state.skip.context() {
  z.return $z_t_skip_context
}

# set the skip state for context level
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t.state.skip.context.set "true"
z.t.state.skip.context.set() {
  z_t_skip_context=$1
}

# get the skip state for it level
#
# REPLY: null
# return: true|false
#
# example:
#  z.t.state.skip.it  #=> "false"
z.t.state.skip.it() {
  z.return $z_t_skip_it
}

# set the skip state for it level
#
# $1: true|false
# REPLY: null
# return: null
#
# example:
#  z.t.state.skip.it.set "true"
z.t.state.skip.it.set() {
  z_t_skip_it=$1
}

# logs array management
#
# REPLY: null
# return: null
#
# example:
#  z.t.state.logs  #=> ("log1" "log2" ...)
z.t.state.logs() {
  z.return ${z_t_logs[@]}
}

# add a log entry
#
# $1: log entry
# REPLY: null
# return: null
#
# example:
#  z.t.state.logs.add "This is a log entry"
z.t.state.logs.add() {
  z_t_logs+=($1)
}

# get a log entry by context
#
# $1: context index
# REPLY: null
# return: log entry
#
# example:
#  z.t.state.logs.context "0"  #=> "log entry at index 0"
z.t.state.logs.context() {
  local context=$1
  z.is_null $context && { z.return ""; return 0; }
  z.return ${z_t_logs[$context]:-""}
}

# set a log entry by context
#
# $1: context index
# $2: log entry
# REPLY: null
# return: null
#
# example:
#  z.t.state.logs.context.set "0" "Updated log entry"
z.t.state.logs.context.set() {
  local context=$1
  local value=$2

  local target_log=${z_t_logs[$context]}

  if z.is_not_null $target_log; then
    z_t_logs[$context]=$value
  fi
}

# get the current index for a context
#
# $1: context ("describe"|"context"|"it")
# REPLY: null
# return: current index
#
# example:
#  z.t.state.current_idx "describe"  #=> 0
z.t.state.current_idx() {
  local context=$1
  z.return ${z_t_current_idx[$context]}
}

# set the current index for a context
#
# $1: context ("describe"|"context"|"it")
# $2: index value
# REPLY: null
# return: null
#
# example:
#  z.t.state.current_idx.set "describe" 1
z.t.state.current_idx.set() {
  local context=$1
  local value=$2
  z_t_current_idx[$context]=$value
}

# add to the current index for a context
#
# $1: context ("describe"|"context"|"it")
# REPLY: null
# return: new index value
#
# example:
#  z.t.state.current_idx.add "describe"
z.t.state.current_idx.add() {
  local context=$1
  z.arr.count $z_t_logs
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

# get failure records
#
# REPLY: null
# return: failure records array
#
# example:
#  z.t.state.failure_records  #=> ("record1" "record2" ...)
z.t.state.failure_records() {
  z.return ${z_t_failure_records[@]}
}

# add a failure record
#
# $1: failure record
# REPLY: null
# return: null
#
# example:
#  z.t.state.failure_records.add "This is a failure record"
z.t.state.failure_records.add() {
  z_t_failure_records+=($1)
}

# get pending records
#
# REPLY: null
# return: pending records array
#
# example:
#  z.t.state.pending_records  #=> ("record1" "record2" ...)
z.t.state.pending_records() {
  z.return ${z_t_pending_records[@]}
}

# add a pending record
#
# $1: pending record
# REPLY: null
# return: null
#
# example:
#  z.t.state.pending_records.add "This is a pending record"
z.t.state.pending_records.add() {
  z_t_pending_records+=($1)
}

# mock originals management
#
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_originals  #=> ("func1" "func2" ...)
z.t.state.mock_originals() {
  z.return ${(k)z_t_mock_originals[@]}
}

# get a mock original by function name
#
# $1: function name
# REPLY: null
# return: original function definition
#
# example:
#  z.t.state.mock_originals.context "my_func"  #=> "original function definition"
z.t.state.mock_originals.context() {
  z.return ${z_t_mock_originals[$1]}
}

# add a mock original
#
# $1: function name
# $2: original function definition
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_originals.add "my_func" "original function definition"
z.t.state.mock_originals.add() {
  local func_name=$1
  local original_func=$2

  z_t_mock_originals[$func_name]=$original_func
}

# unset a mock original
#
# $1: function name
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_originals.unset "my_func"
z.t.state.mock_originals.unset() {
  unset "z_t_mock_originals[$1]" 2>/dev/null
}

# mock saved indexes management
#
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_saved_indexes  #=> ("index1" "index2" ...)
z.t.state.mock_saved_indexes() {
  z.return ${z_t_mock_saved_indexes[@]}
}

# get a mock saved index by context
#
# $1: context index
# REPLY: null
# return: saved index
#
# example:
#  z.t.state.mock_saved_indexes.context "0"  #=> "saved index at index 0"
z.t.state.mock_saved_indexes.context() {
  z.return ${z_t_mock_saved_indexes[$1]}
}

# add a mock saved index
#
# $1: context index
# $2: saved index value
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_saved_indexes.add "0" "saved index value"
z.t.state.mock_saved_indexes.add() {
  local key=$1
  local value=$2
  z_t_mock_saved_indexes[$key]=$value
}

# unset a mock saved index
#
# $1: context index
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_saved_indexes.unset "0"
z.t.state.mock_saved_indexes.unset() {
  unset "z_t_mock_saved_indexes[$1]" 2>/dev/null
}

# mock calls management
#
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_calls  #=> ("call1" "call2" ...)
z.t.state.mock_calls() {
  z.return ${z_t_mock_calls[@]}
}

# get mock calls by function name
#
# $1: function name
# REPLY: null
# return: mock calls
#
# example:
#  z.t.state.mock_calls.context "my_func"  #=> "mock calls for my_func"
z.t.state.mock_calls.context() {
  z.return ${z_t_mock_calls[$1]}
}

# add a mock call
#
# $1: function name
# $2: arguments
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_calls.add "my_func" "arg1" "arg2"
z.t.state.mock_calls.add() {
  local func_name=$1 && shift
  local args=$@

  if z.is_not_null ${z_t_mock_calls[$func_name]}; then
    z_t_mock_calls[$func_name]="${z_t_mock_calls[$func_name]}:$args"
  else
    z_t_mock_calls[$func_name]=$args
  fi
}

# set mock calls for a function
#
# $1: function name
# $2: value
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_calls.set "my_func" "new value"
z.t.state.mock_calls.set() {
  local func_name=$1
  local value=$2

  z_t_mock_calls[$func_name]=$value
}

# unset mock calls for a function
#
# $1: function name
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_calls.unset "my_func"
z.t.state.mock_calls.unset() {
  unset "z_t_mock_calls[$1]" 2>/dev/null
}

# get the last mocked function name
#
# REPLY: null
# return: function name
#
# example:
#  z.t.state.mock_last_func  #=> "my_mocked_function"
z.t.state.mock_last_func() {
  z.return $z_t_mock_last_func
}

# set the last mocked function name
#
# $1: function name
# REPLY: null
# return: null
#
# example:
#  z.t.state.mock_last_func.set "my_mocked_function"
z.t.state.mock_last_func.set() {
  z_t_mock_last_func=$1
}
