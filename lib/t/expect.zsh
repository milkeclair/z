for expect_file in ${z_root}/lib/t/expect/*.zsh; do
  source ${expect_file} $1
done

# expect that actual equals expect
#
# $1: actual value
# $2: expected value
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  z.t.expect $actual $expect
z.t.expect() {
  local actual=$1
  local expect=$2
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t._state.skip.it
  if z.is_true $REPLY; then
    z.t.mock.unmock.all skip_unmock=$skip_unmock
    return 0
  fi

  if z.not_eq $expect $actual; then
    local expect_display=${(V)expect}
    local actual_display=${(V)actual}
    z.t._log.failure.handle "message=failed: expected [ $expect_display ] but got [ $actual_display ]"
  fi

  z.t.mock.unmock.all skip_unmock=$skip_unmock
}

# expect that actual does not equal expect
#
# $1: actual value
# $2: expected value
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  z.t.expect.not $actual $expect
z.t.expect.not() {
  local actual=$1
  local expect=$2
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t._state.skip.it
  if z.is_true $REPLY; then
    z.t.mock.unmock.all skip_unmock=$skip_unmock
    return 0
  fi

  if z.eq $expect $actual; then
    local expect_display=${(V)expect}
    local actual_display=${(V)actual}
    z.t._log.failure.handle "message=failed: expected not [ $expect_display ] but got [ $actual_display ]"
  fi

  z.t.mock.unmock.all skip_unmock=$skip_unmock
}
