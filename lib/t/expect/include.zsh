# expect that actual includes expect
#
# $1: actual value
# $2: expected substring
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  z.t.expect.include $actual $expect
z.t.expect.include() {
  local actual=$1
  local expect=$2
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t._state.skip.it
  if z.is_true $REPLY; then
    z.t.mock.unmock.all skip_unmock=$skip_unmock
    return 0
  fi

  if z.str.exclude $actual $expect; then
    z.t._log.failure.handle "message=failed: expected [ $expect ] to be included in [ $actual ]"
  fi

  z.t.mock.unmock.all skip_unmock=$skip_unmock
}

# expect that actual excludes expect
#
# $1: actual value
# $2: expected substring
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  z.t.expect.exclude $actual $expect
z.t.expect.exclude() {
  local actual=$1
  local expect=$2
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t._state.skip.it
  if z.is_true $REPLY; then
    z.t.mock.unmock.all skip_unmock=$skip_unmock
    return 0
  fi

  if z.str.include $actual $expect; then
    z.t._log.failure.handle "message=failed: expected [ $expect ] to be excluded from [ $actual ]"
  fi

  z.t.mock.unmock.all skip_unmock=$skip_unmock
}
