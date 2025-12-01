# expect that REPLY array equals expect array
#
# $@: expected array elements
# $skip_unmock?: skip_unmock
# REPLY: null
# return: null
#
# example:
#  REPLY=("a" "b" "c")
#  z.t.expect.reply.is.arr "a" "b" "c"
z.t.expect.reply.is.arr() {
  local actual=($REPLY)

  local args=($@)
  local skip_unmock=""
  z.arg.last $args

  if z.str.includes $REPLY "skip_unmock="; then
    skip_unmock=true
    args=(${args[1,-2]})
  fi

  local expect=($args)

  z.arr.join ${expect[@]}
  local expect_str=$REPLY
  z.arr.join ${actual[@]}
  local actual_str=$REPLY

  z.t.expect "$actual_str" "$expect_str" "skip_unmock=$skip_unmock"
}
