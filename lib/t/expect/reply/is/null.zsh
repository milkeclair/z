# expect that REPLY is null (empty string)
#
# $skip_unmock?: skip_unmock
# REPLY: null
# return: null
#
# example:
#  REPLY=""
#  z.t.expect.reply.is.null
z.t.expect.reply.is.null() {
  local expect=""
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect "$reply" "$expect" "skip_unmock=$skip_unmock"
}
