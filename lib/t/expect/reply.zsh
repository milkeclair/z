# expect that REPLY equals expect
#
# $1: expected value
# $2: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY="some value"
#  z.t.expect.reply "some value"
z.t.expect.reply() {
  local expect=$1
  local skip_unmock=$2

  z.t.expect "$REPLY" "$expect" "$skip_unmock"
}

# expect that REPLY is null (empty string)
#
# $1: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY=""
#  z.t.expect.reply.null
z.t.expect.reply.null() {
  local expect=""
  local skip_unmock=$1

  z.t.expect "$REPLY" "$expect" "$skip_unmock"
}

# expect that REPLY is not null (not empty string)
#
# $1: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY="some value"
#  z.t.expect.reply.not_null
z.t.expect.reply.not_null() {
  local expect=""
  local skip_unmock=$1

  z.t.expect.not "$REPLY" "$expect" "$skip_unmock"
}

# expect that REPLY array equals expect array
#
# $@: expected array elements
# REPLY: null
# return: null
#
# example:
#  REPLY=("a" "b" "c")
#  z.t.expect.reply.arr "a" "b" "c"
z.t.expect.reply.arr() {
  local -a actual=($REPLY)

  local -a args=($@)
  local skip_unmock=""
  z.arg.last $args

  if z.eq $REPLY "skip_unmock"; then
    skip_unmock="skip_unmock"
    args=(${args[1,-2]})
  fi

  local -a expect=($args)

  z.arr.join ${expect[@]}
  local expect_str=$REPLY
  z.arr.join ${actual[@]}
  local actual_str=$REPLY

  z.t.expect "$actual_str" "$expect_str" "$skip_unmock"
}

# expect that REPLY includes expect
#
# $1: expected substring
# $2: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY="some long string"
#  z.t.expect.reply.include "long"
z.t.expect.reply.include() {
  local expect=$1
  local skip_unmock=$2

  z.t.expect.include $REPLY $expect $skip_unmock
}
