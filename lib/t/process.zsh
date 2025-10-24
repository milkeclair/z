# run tests
# options:
#   -l|--log: show all logs
#   -f|--failed: show only failed tests
#   -c|--compact: show compact dot output
#   <test_name>: run specific test(s)
#
# $@: options and test names
# REPLY: null
# return: 0|1
#
# example:
#  z.t
#  z.t -l
#  z.t -f
#  z.t -c
#  z.t some_test_name
z.t() {
  z.t._extract_options $@
  local -a z_t_options=($REPLY)
  local z_t_all_log=${z_t_options[1]:-"false"}
  local z_t_failed_only=${z_t_options[2]:-"false"}
  local z_t_compact=${z_t_options[3]:-"false"}
  local -a test_names=()
  if z.int.gt ${#z_t_options[@]} 3; then
    test_names=(${z_t_options[@]:3})
  fi

  local original_dir=$PWD

  local z_mode="test"
  local test_root=${Z_TEST_ROOT:-$PWD}
  z.dir.is "${test_root}/test" && test_root="${test_root}/test"
  local root_dir=${test_root:h}
  local z_main="${root_dir}/main.zsh"
  cd $test_root

  z.io.empty
  z.io "================ Running tests ================"
  z.io.empty

  z.arr.count $test_names
  local name_count=$REPLY
  local files=()

  if z.int.gt $name_count 0; then
    for name in $test_names; do
      files+=(**/*${name}_test.zsh)
    done
  else
    files=(**/*_test.zsh)
  fi

  local file_count=${#files[@]}
  local failed=0

  z.t._setup_temp_dirs
  local compact_dir=$REPLY
  local count_dir=${z_t_count_dir:-}

  local file_idx=0
  for test_file in $files; do
    ((file_idx++))

    Z_ROOT=$root_dir \
      Z_DEBUG=0 \
      z_mode=$z_mode \
      z_main=$z_main \
      Z_TEST_ALL_LOG=$z_t_all_log \
      Z_TEST_FAILED_ONLY=$z_t_failed_only \
      Z_TEST_COMPACT=$z_t_compact \
      Z_TEST_COMPACT_DIR=$compact_dir \
      Z_TEST_COMPACT_IDX=$file_idx \
      Z_TEST_COUNT_DIR=$count_dir \
      Z_TEST_COUNT_IDX=$file_idx \
        zsh $test_file $test_file

    local exit_code=$?

    z.t.state.failures
    local test_failures=$REPLY

    z.int.is_not_zero $test_failures && failed=1
    z.int.is_not_zero $exit_code && failed=1

    ((file_count--))
    if z.is_true $z_t_all_log && z.int.gt $file_count 0; then
      z.is_false $z_t_compact && z.io.empty
    fi
  done

  z.is_true $z_t_compact && z.t._show_compact_results $compact_dir $files

  z.t._show_totals $count_dir $files
  local totals_failed=$?

  cd $original_dir
  z.int.is_not_zero $failed && return 1
  return $totals_failed
}

# extract options from arguments
#
# $@: arguments
# REPLY: "<log> <failed> <compact> <test_names...>"
# return: null
#
# example:
#  z.t._extract_options -l -f -c some_test_name
#  REPLY="true true true some_test_name"
z.t._extract_options() {
  z.arr.count $@
  local arg_count=$REPLY
  local log="false"
  local failed="false"
  local compact="false"
  local -a test_names=()

  if z.int.gteq $arg_count 1; then
    for ((i=1; i<=arg_count; i++)); do
      z.arg.get $i $@
      local current_arg=$REPLY

      z.arg.as $current_arg "-l|--log" "true"
      if z.is_true $REPLY; then
        log="true"
        continue
      fi

      z.arg.as $current_arg "-f|--failed" "true"
      if z.is_true $REPLY; then
        failed="true"
        continue
      fi

      z.arg.as $current_arg "-c|--compact" "true"
      if z.is_true $REPLY; then
        compact="true"
        continue
      fi

      test_names+=($current_arg)
    done
  fi

  local -a result=($log $failed $compact)
  if z.int.gt ${#test_names[@]} 0; then
    result+=($test_names)
  fi

  z.return ${result[@]}
}

# remove temporary test directory /tmp/z_t
#
# REPLY: null
# return: null
#
# example:
#  z.t.remove_tmp_dir
z.t.remove_tmp_dir() {
  z.dir.is /tmp/z_t && rm -rf /tmp/z_t
}

# internal: setup temporary directories for test execution
#
# REPLY: compact_dir (empty string if not compact mode)
# return: null
#
# example:
#  z.t._setup_temp_dirs
z.t._setup_temp_dirs() {
  local compact_dir=""

  if z.is_true $z_t_compact; then
    compact_dir="/tmp/z_t_compact_$$"
    z.dir.make $compact_dir
    echo "0" > "$compact_dir/.dot_count"
  fi

  typeset -g z_t_count_dir="/tmp/z_t_count_$$"
  z.dir.make $z_t_count_dir

  z.return $compact_dir
}

# internal: display compact mode results
#
# $1: compact_dir
# $@: files list
# REPLY: null
# return: null
#
# example:
#  z.t._show_compact_results $compact_dir $files
z.t._show_compact_results() {
  local compact_dir=$1 && shift
  local -a files=($@)

  z.io.empty
  z.io.empty

  local file_idx=0
  for test_file in $files; do
    ((file_idx++))
    local summary_file="$compact_dir/${file_idx}_summary.txt"
    z.file.is $summary_file && cat $summary_file
  done

  local -a failure_files=("$compact_dir"/*_failure.txt)
  if z.int.gt ${#failure_files[@]} 0; then
    for failure_file in ${failure_files[@]}; do
      z.file.is $failure_file && cat $failure_file
    done
  fi
}

# internal: calculate and display total counts
#
# $1: count_dir
# $@: files list
# REPLY: null
# return: 0|1 (0 if no failures, 1 if failures)
#
# example:
#  z.t._show_totals $count_dir $files
z.t._show_totals() {
  local count_dir=$1 && shift
  local -a files=($@)

  local total_tests=0
  local total_failures=0
  local total_pendings=0

  local file_idx=0
  for test_file in $files; do
    ((file_idx++))
    local count_file="$count_dir/${file_idx}_count.txt"
    if z.file.is $count_file; then
      local counts=$(cat $count_file)
      local -a count_array=(${=counts})
      ((total_tests += ${count_array[1]:-0}))
      ((total_failures += ${count_array[2]:-0}))
      ((total_pendings += ${count_array[3]:-0}))
    fi
  done

  z.dir.remove $count_dir

  z.io.empty
  local padded_total_tests=$(printf "%3s" $total_tests)
  local padded_total_failures=$(printf "%2s" $total_failures)
  local padded_total_pendings=$(printf "%2s" $total_pendings)
  local total_message="total: $padded_total_tests tests $padded_total_failures failures $padded_total_pendings pendings"

  if z.int.is_zero $total_failures; then
    z.str.color.green "$total_message"
  else
    z.str.color.red "$total_message"
  fi

  z.io $REPLY

  z.int.is_not_zero $total_failures && return 1 || return 0
}
