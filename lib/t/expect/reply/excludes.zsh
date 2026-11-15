# expect that REPLY excludes expect
#
# $1: expected substring
# $skip_unmock?: skip_unmock
# REPLY: null
# return: null
#
# example:
#  REPLY="some long string"
#  z.t.expect.reply.excludes "short"
z.t.expect.reply.excludes() {
  local expect=$1
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect.excludes "$reply" "$expect" "skip_unmock=$skip_unmock"
}
