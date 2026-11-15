# expect that actual includes expect
#
# $1: actual value
# $2: expected substring
# $skip_unmock?: skip_unmock
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

# expect that actual excludes expect
#
# $1: actual value
# $2: expected substring
# $skip_unmock?: skip_unmock
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
