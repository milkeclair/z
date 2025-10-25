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

  z.str.indent level=1 message=$description
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

  z.str.indent level=1 message=$description
  z.str.color.yellow $REPLY

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "describe"
  z.t._state.skip.describe.set "true"
  z.t._state.skip.context.set "true"
  z.t._state.skip.it.set "true"
}
