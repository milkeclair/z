z.t() {
  local -a test_names=()
  local z_all_log="false"
  local z_failed_only="false"

  z.arr.count $@
  local arg_count=$REPLY

  if z.int.gteq $arg_count 1; then
    for ((i=1; i<=arg_count; i++)); do
      z.arg.get $i $@
      local current_arg=$REPLY

      z.arg.as $current_arg "-l|--log" 0
      if z.is_not_null $REPLY; then
        z_all_log=$REPLY
        continue
      fi

      z.arg.as $current_arg "-f|--failed" 0
      if z.is_not_null $REPLY; then
        z_failed_only=$REPLY
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

  for test_file in $files; do
    Z_ROOT=$root_dir Z_DEBUG=0 z_mode=$z_mode z_all_log=$z_all_log z_failed_only=$z_failed_only z_main=$z_main  \
      zsh $test_file $test_file

    ((file_count--))
    { z.int.gt $file_count 0 && z.is_true $z_all_log; } &&
      z.io.empty
  done

  cd $original_dir
}
