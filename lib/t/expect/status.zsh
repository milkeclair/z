# expect that last command's exit status equals expect
#
# $1: expected status (0 for true, 1 for false, "true" for 0, "false" for 1)
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  some_command
#  z.t.expect.status 0
z.t.expect.status() {
  local actual=$?
  local expect=$1
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.eq $expect "true" && expect=0
  z.eq $expect "false" && expect=1

  z.t.expect "$actual" "$expect" "skip_unmock=$skip_unmock"
}

# expect that last command's exit status is true (0)
#
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  some_command
#  z.t.expect.status.true
z.t.expect.status.true() {
  z.t.expect.status true $1 # 変数に格納した時点で$?が変わるので、$1を直接渡す
}

# expect that last command's exit status is false (1)
#
# $skip_unmock: skip_unmock (optional)
# REPLY: null
# return: null
#
# example:
#  some_command
#  z.t.expect.status.false
z.t.expect.status.false() {
  z.t.expect.status false $1 # 変数に格納した時点で$?が変わるので、$1を直接渡す
}
