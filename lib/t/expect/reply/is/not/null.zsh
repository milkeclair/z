# expect that REPLY is not null (not empty string)
#
# $skip_unmock?: skip_unmock
# REPLY: null
# return: null
#
# example:
#  REPLY="some value"
#  z.t.expect.reply.is.not.null
z.t.expect.reply.is.not.null() {
  local expect=""
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect.not "$reply" "$expect" "skip_unmock=$skip_unmock"
}
