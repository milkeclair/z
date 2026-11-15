# expect that last command's exit status equals expect
#
# $1: expected status (0 for true, 1 for false, "true" for 0, "false" for 1)
# $skip_unmock?: skip_unmock
# REPLY: null
# return: null
#
# example:
#  some_command
#  z.t.expect.status 0
z.t.expect.status() {
  z.status
  local actual=$REPLY
  local expect=$1
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.is.eq $expect "true" && expect=0
  z.is.eq $expect "false" && expect=1

  z.t.expect "$actual" "$expect" "skip_unmock=$skip_unmock"
}
