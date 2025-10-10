z.t() {
  local -a test_names=()
  local z_test_all_log="false"
  local z_test_failed_only="false"

  z.arr.count $@
  local arg_count=$REPLY

  if z.int.gteq $arg_count 1; then
    for ((i=1; i<=arg_count; i++)); do
      z.arg.get $i $@
      local current_arg=$REPLY

      z.arg.as $current_arg "-l|--log" 0
      if z.is_not_null $REPLY; then
        z_test_all_log=$REPLY
        continue
      fi

      z.arg.as $current_arg "-f|--failed" 0
      if z.is_not_null $REPLY; then
        z_test_failed_only=$REPLY
        continue
      fi

      test_names+=($current_arg)
    done
  fi

  local z_mode="test"
  local test_root=${Z_TEST_ROOT:-$PWD}
  z.dir.is "${test_root}/test" && test_root="${test_root}/test"
  local root_dir=${test_root:h}
  local z_main=${root_dir}/main.zsh

  z.io.empty
  z.io "================ Running tests ================"
  z.io.empty

  local original_dir=$PWD
  cd $test_root

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

  for test_file in $files; do
    Z_ROOT=$root_dir Z_DEBUG=0 z_mode=$z_mode z_main=$z_main \
      Z_TEST_ALL_LOG=$z_test_all_log Z_TEST_FAILED_ONLY=$z_test_failed_only \
      zsh $test_file $test_file

    local exit_code=$?

    z.t.state.failures
    local test_failures=$REPLY

    z.int.is_not_zero $test_failures && failed=1
    z.int.is_not_zero $exit_code && failed=1

    ((file_count--))
    z.is_true $z_test_all_log && z.int.gt $file_count 0 && z.io.empty
  done

  cd $original_dir
  z.int.is_not_zero $failed && return 1 || return 0
}

z.t.remove_tmp_dir() {
  z.dir.is /tmp/z_test && rm -rf /tmp/z_test
}
