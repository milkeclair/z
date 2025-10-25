# expect that REPLY equals expect
#
# $1: expected value
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY="some value"
#  z.t.expect.reply "some value"
z.t.expect.reply() {
  local expect=$1
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect "$reply" "$expect" "skip_unmock=$skip_unmock"
}

# expect that REPLY is null (empty string)
#
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY=""
#  z.t.expect.reply.null
z.t.expect.reply.null() {
  local expect=""
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect "$reply" "$expect" "skip_unmock=$skip_unmock"
}

# expect that REPLY is not null (not empty string)
#
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY="some value"
#  z.t.expect.reply.not_null
z.t.expect.reply.not_null() {
  local expect=""
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect.not "$reply" "$expect" "skip_unmock=$skip_unmock"
}

# expect that REPLY array equals expect array
#
# $@: expected array elements
# $skip_unmock: skip_unmock (optional)
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

  if z.str.is_include $REPLY "skip_unmock="; then
    skip_unmock=true
    args=(${args[1,-2]})
  fi

  local -a expect=($args)

  z.arr.join ${expect[@]}
  local expect_str=$REPLY
  z.arr.join ${actual[@]}
  local actual_str=$REPLY

  z.t.expect "$actual_str" "$expect_str" "skip_unmock=$skip_unmock"
}

# expect that REPLY includes expect
#
# $1: expected substring
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  REPLY="some long string"
#  z.t.expect.reply.include "long"
z.t.expect.reply.include() {
  local expect=$1
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect.include "$reply" "$expect" "skip_unmock=$skip_unmock"
}
