# expect that REPLY includes expect
#
# $1: expected substring
# $skip_unmock?: skip_unmock
# REPLY: null
# return: null
#
# example:
#  REPLY="some long string"
#  z.t.expect.reply.includes "long"
z.t.expect.reply.includes() {
  local expect=$1
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect.includes "$reply" "$expect" "skip_unmock=$skip_unmock"
}
