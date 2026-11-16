# 直前のコマンドの終了コードがfalse（1）であることを検証する
#
# $1?: モック解除を省略するか
# REPLY: null
# return: null
#
# example:
#  false
#  z.t.expect.status.is.false
#  # 結果: 検証成功（失敗件数は増えない）
z.t.expect.status.is.false() {
  z.t.expect.status false $1 # 変数に格納した時点で$?が変わるので、$1を直接渡す
}
