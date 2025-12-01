# teardown function to be called at the end of tests
#
# REPLY: null
# return: null
#
# example:
#  z.t.teardown
z.t.teardown() {
  z.t.mock.unmock.all
  z.t._remove_tmp_dir

  local error_flag_file="/tmp/z_t_error_$$"
  if z.file.exists $error_flag_file; then
    local error_lines
    error_lines=(${(f)$(<$error_flag_file)})
    z.arr.count $error_lines
    local error_count=$REPLY

    local i
    for ((i=1; i<=error_count; i++)); do
      local error_message=${error_lines[$i]}
      z.t._log.failure.handle message=$error_message
    done

    z.dir.remove path=$error_flag_file
  fi

  z.t._state.compact
  if z.is.true $REPLY; then
    z.t._state.tests
    local test_count=$REPLY
    if z.int.is.gt $test_count 0; then
      z.t._state.current_it_failures
      local failures=$REPLY
      if z.int.is.zero $failures; then
        z.t._state.skip.it
        z.is.false $REPLY && z.t._log.dot.success
      else
        z.t._log.dot.failure
      fi
    fi
  fi

  z.t._log.show

  z.t._state.failures
  z.int.is.not.zero $REPLY && exit 1
}
