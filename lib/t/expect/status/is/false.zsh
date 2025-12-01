# expect that last command's exit status is false (1)
#
# $1?: skip_unmock
# REPLY: null
# return: null
#
# example:
#  some_command
#  z.t.expect.status.is.false
z.t.expect.status.is.false() {
  z.t.expect.status false $1 # 変数に格納した時点で$?が変わるので、$1を直接渡す
}
