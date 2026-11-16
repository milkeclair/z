# テストスイートを定義する
#
# $1: 説明
# REPLY: null
# return: null
#
# example:
#  z.t.describe "My Test Suite"; {some tests}
z.t.describe() {
  local REPLY
  local description=$1

  z.t._log.format "  " green "$description"

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "describe"
  z.t._state.skip.describe.set "false"
  z.t._state.skip.context.set "false"
  z.t._state.skip.it.set "false"
}

# テストスイートをxdescribeで定義する（保留扱い）
#
# $1: 説明
# REPLY: null
# return: null
#
# example:
#  z.t.xdescribe "My Pending Test Suite"; {some tests}
z.t.xdescribe() {
  local REPLY
  local description=$1

  z.t._log.format "  " yellow "$description"

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "describe"
  z.t._state.skip.describe.set "true"
  z.t._state.skip.context.set "true"
  z.t._state.skip.it.set "true"
}
