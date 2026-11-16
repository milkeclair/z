# REPLYがnullであることを検証する（空文字列）
#
# $skip_unmock?: モック解除を省略するか
# REPLY: null
# return: null
#
# example:
#  REPLY=""
#  z.t.expect.reply.is.null
#  # 結果: 検証成功（失敗件数は増えない）
z.t.expect.reply.is.null() {
  local expect=""
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect "$reply" "$expect" "skip_unmock=$skip_unmock"
}
