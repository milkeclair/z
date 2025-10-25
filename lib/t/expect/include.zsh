# expect that actual includes expect
#
# $1: actual value
# $2: expected substring
# $3: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  z.t.expect.include $actual $expect
z.t.expect.include() {
  local actual=$1
  local expect=$2
  local skip_unmock=$3

  z.t._state.skip.it
  if z.is_true $REPLY; then
    z.t.mock.unmock.all $skip_unmock
    return 0
  fi

  if z.str.is_not_include $actual $expect; then
    z.t._log.failure.handle "failed: expected [ $expect ] to be included in [ $actual ]"
  fi

  z.t.mock.unmock.all $skip_unmock
}

# expect that actual excludes expect
#
# $1: actual value
# $2: expected substring
# $3: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  z.t.expect.exclude $actual $expect
z.t.expect.exclude() {
  local actual=$1
  local expect=$2
  local skip_unmock=$3

  z.t._state.skip.it
  if z.is_true $REPLY; then
    z.t.mock.unmock.all $skip_unmock
    return 0
  fi

  if z.str.is_include $actual $expect; then
    z.t._log.failure.handle "failed: expected [ $expect ] to be excluded from [ $actual ]"
  fi

  z.t.mock.unmock.all $skip_unmock
}
