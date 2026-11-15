# context within a test suite
#
# $1: context description
# REPLY: null
# return: null
#
# example:
#  z.t.context "When something happens"; {some tests}
z.t.context() {
  local REPLY
  local context=$1

  z.t._state.skip.describe
  local describe_skip=$REPLY

  if z.is.true $describe_skip; then
    z.t._log.format "    " yellow "$context"
  else
    z.t._log.format "    " green "$context"
  fi

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "context"

  if z.is.true $describe_skip; then
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
  local REPLY
  local context=$1

  z.t._log.format "    " yellow "$context"

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "context"
  z.t._state.skip.describe
  z.t._state.skip.context.set "true"
  z.t._state.skip.it.set "true"
}
