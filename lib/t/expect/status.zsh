# 直前のコマンドの終了コードが期待値と等しいことを検証する
#
# $1: 期待する終了コード（trueは0、falseは1。"true"は0、"false"は1）
# $skip_unmock?: モック解除を省略するか
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
