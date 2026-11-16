# REPLYが期待値と等しいことを検証する
#
# $1: 期待値
# $skip_unmock?: モック解除を省略するか
# REPLY: null
# return: null
#
# example:
#  REPLY="some value"
#  z.t.expect.reply "some value"
#  # 結果: 検証成功（失敗件数は増えない）
z.t.expect.reply() {
  local expect=$1
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect "$reply" "$expect" "skip_unmock=$skip_unmock"
}
