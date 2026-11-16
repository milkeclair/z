# 実際の値に期待値が含まれることを検証する
#
# $1: 実際の値
# $2: 期待する部分文字列
# $skip_unmock?: モック解除を省略するか
# REPLY: null
# return: null
#
# example:
#  z.t.expect.includes $actual $expect
z.t.expect.includes() {
  local actual=$1
  local expect=$2
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t._state.skip.it
  if z.is.true $REPLY; then
    z.t.mock.unmock.all skip_unmock=$skip_unmock
    return 0
  fi

  if z.str.excludes "$actual" "$expect"; then
    z.t._log.failure.handle "message=failed: expected [ $expect ] to be included in [ $actual ]"
  fi

  z.t.mock.unmock.all skip_unmock=$skip_unmock
}

# 実際の値に期待値が含まれないことを検証する
#
# $1: 実際の値
# $2: 期待する部分文字列
# $skip_unmock?: モック解除を省略するか
# REPLY: null
# return: null
#
# example:
#  z.t.expect.excludes $actual $expect
z.t.expect.excludes() {
  local actual=$1
  local expect=$2
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t._state.skip.it
  if z.is.true $REPLY; then
    z.t.mock.unmock.all skip_unmock=$skip_unmock
    return 0
  fi

  if z.str.includes "$actual" "$expect"; then
    z.t._log.failure.handle "message=failed: expected [ $expect ] to be excluded from [ $actual ]"
  fi

  z.t.mock.unmock.all skip_unmock=$skip_unmock
}
