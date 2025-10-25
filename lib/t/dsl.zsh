z.eq $z_mode "test" && {
  trap "z.t.teardown" EXIT

  command_not_found_handler() {
    local cmd=$1
    z.t._mark_not_found_error "command not found: $cmd"
    return 127
  }
}

# mark the test suite as having command not found error
#
# $1: error message
# REPLY: null
# return: 127(command not found)
#
# example:
#  z.t.mark_not_found_error "command not found: ls"
z.t._mark_not_found_error() {
  local message=$1

  local error_flag_file="/tmp/z_t_error_$$"
  z.file.make_with_dir $error_flag_file
  echo $message >> $error_flag_file

  return 127
}

# describe a test suite
#
# $1: description
# REPLY: null
# return: null
#
# example:
#  z.t.describe "My Test Suite"; {some tests}
z.t.describe() {
  local description=$1

  z.str.indent 1 $description
  z.str.color.green $REPLY

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "describe"
  z.t._state.skip.describe.set "false"
  z.t._state.skip.context.set "false"
  z.t._state.skip.it.set "false"
}

# xdescribe a test suite (marked as pending)
#
# $1: description
# REPLY: null
# return: null
#
# example:
#  z.t.xdescribe "My Pending Test Suite"; {some tests}
z.t.xdescribe() {
  local description=$1

  z.str.indent 1 $description
  z.str.color.yellow $REPLY

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "describe"
  z.t._state.skip.describe.set "true"
  z.t._state.skip.context.set "true"
  z.t._state.skip.it.set "true"
}

# context within a test suite
#
# $1: context description
# REPLY: null
# return: null
#
# example:
#  z.t.context "When something happens"; {some tests}
z.t.context() {
  local context=$1

  z.t._state.skip.describe
  local describe_skip=$REPLY

  z.str.indent 2 $context
  if z.is_true $describe_skip; then
    z.str.color.yellow $REPLY
  else
    z.str.color.green $REPLY
  fi

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "context"

  if z.is_true $describe_skip; then
    z.t._state.skip.context.set "true"
    z.t._state.skip.it.set "true"
  else
    z.t._state.skip.context.set "false"
    z.t._state.skip.it.set "false"
  fi
}

# xcontext within a test suite (marked as pending)
#
# $1: context description
# REPLY: null
# return: null
#
# example:
#  z.t.xcontext "When something happens"; {some tests}
z.t.xcontext() {
  local context=$1

  z.str.indent 2 $context
  z.str.color.yellow $REPLY

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "context"
  z.t._state.skip.describe
  z.t._state.skip.context.set "true"
  z.t._state.skip.it.set "true"
}

# it block within a test suite
#
# $1: it description
# REPLY: null
# return: null
#
# example:
#  z.t.it "should do something"; {test code}
z.t.it() {
  REPLY=""

  local it=$1

  z.t._state.skip.describe
  local describe_skip=$REPLY
  z.t._state.skip.context
  local context_skip=$REPLY

  z.t._state.compact
  local is_compact=$REPLY

  if z.is_true $is_compact; then
    z.t._state.tests
    local test_count=$REPLY
    if z.int.gt $test_count 0; then
      z.t._state.current_it_failures
      local failures=$REPLY
      if z.int.is_zero $failures; then
        z.t._state.skip.it
        z.is_false $REPLY && z.t._log.dot.success
      else
        z.t._log.dot.failure
      fi
    fi
    z.t._state.current_it_failures.reset
  fi

  z.str.indent 3 $it
  if z.is_true $describe_skip || z.is_true $context_skip; then
    z.str.color.yellow $REPLY
  else
    z.str.color.green $REPLY
  fi

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "it"
  z.t._state.tests.increment

  if z.is_true $describe_skip || z.is_true $context_skip; then
    z.t._state.skip.it.set "true"
    z.t._state.pendings.increment

    z.t._state.current_idx "describe"
    local d_idx=$REPLY
    z.t._state.current_idx "context"
    local c_idx=$REPLY
    z.t._state.current_idx "it"
    local i_idx=$REPLY
    z.t._state.pending_records.add "$d_idx:$c_idx:$i_idx"

    if z.is_true $is_compact; then
      z.t._log.dot.pending
    fi
  else
    z.t._state.skip.it.set "false"
  fi
}

# xit block within a test suite (marked as pending)
#
# $1: it description
# REPLY: null
# return: null
#
# example:
#  z.t.xit "should do something"; {test code}
z.t.xit() {
  REPLY=""

  local it=$1

  z.t._state.compact
  local is_compact=$REPLY

  if z.is_true $is_compact; then
    z.t._state.tests
    local test_count=$REPLY
    if z.int.gt $test_count 0; then
      z.t._state.current_it_failures
      local failures=$REPLY
      if z.int.is_zero $failures; then
        z.t._state.skip.it
        z.is_false $REPLY && z.t._log.dot.success
      else
        z.t._log.dot.failure
      fi
    fi
    z.t._state.current_it_failures.reset
  fi

  z.str.indent 3 $it
  z.str.color.yellow $REPLY
  z.t._state.logs.add $REPLY

  z.t._state.current_idx.add "it"
  z.t._state.tests.increment
  z.t._state.pendings.increment
  z.t._state.skip.it.set "true"

  z.t._state.current_idx "describe"
  local d_idx=$REPLY
  z.t._state.current_idx "context"
  local c_idx=$REPLY
  z.t._state.current_idx "it"
  local i_idx=$REPLY
  z.t._state.pending_records.add "$d_idx:$c_idx:$i_idx"

  if z.is_true $is_compact; then
    z.t._log.dot.pending
  fi
}

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
  if z.file.is $error_flag_file; then
    local -a error_lines
    error_lines=("${(@f)$(<$error_flag_file)}")
    z.arr.count $error_lines
    local error_count=$REPLY

    local i
    for ((i=1; i<=error_count; i++)); do
      local error_message=${error_lines[$i]}
      z.t._log.failure.handle $error_message
    done

    z.dir.remove $error_flag_file
  fi

  z.t._state.compact
  if z.is_true $REPLY; then
    z.t._state.tests
    local test_count=$REPLY
    if z.int.gt $test_count 0; then
      z.t._state.current_it_failures
      local failures=$REPLY
      if z.int.is_zero $failures; then
        z.t._state.skip.it
        z.is_false $REPLY && z.t._log.dot.success
      else
        z.t._log.dot.failure
      fi
    fi
  fi

  z.t._log.show

  z.t._state.failures
  z.int.is_not_zero $REPLY && exit 1
}
