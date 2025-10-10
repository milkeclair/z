z.eq $z_mode "test" && {
  trap "z.t.teardown" EXIT

  command_not_found_handler() {
    local cmd=$1
    z.t.state.mark_error "command not found: $cmd"
    return 127
  }
}

z.t.describe() {
  local description=$1

  z.str.indent 1 $description
  z.str.color.green $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "describe"
}

z.t.xdescribe() {
  local description=$1

  z.str.indent 1 $description
  z.str.color.yellow $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "describe"
}

z.t.context() {
  local context=$1

  z.str.indent 2 $context
  z.str.color.green $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "context"
}

z.t.xcontext() {
  local context=$1

  z.str.indent 2 $context
  z.str.color.yellow $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "context"
}

z.t.it() {
  REPLY=""

  local it=$1

  z.str.indent 3 $it
  z.str.color.green $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "it"
  z.t.state.tests.increment
}

z.t.xit() {
  REPLY=""

  local it=$1

  z.str.indent 3 $it
  z.str.color.yellow $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "it"
  z.t.state.tests.increment
}

z.t.teardown() {
  z.t.mock.unmock.all
  z.t.remove_tmp_dir

  local error_flag_file="/tmp/z_test_error_$$"
  if [[ -f "$error_flag_file" ]]; then
    local -a error_lines
    error_lines=("${(@f)$(<$error_flag_file)}")
    z.arr.count $error_lines
    local error_count=$REPLY

    local i
    for ((i=1; i<=error_count; i++)); do
      local error_message=${error_lines[$i]}
      z.t.log.failure.handle $error_message
    done

    z.dir.remove $error_flag_file
  fi
  
  z.t.log.show

  z.t.state.failures
  z.int.is_not_zero $REPLY && exit 1
}
