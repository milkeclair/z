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
