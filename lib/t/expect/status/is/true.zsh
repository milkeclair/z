# 直前のコマンドの終了コードがtrue（0）であることを検証する
#
# $1?: モック解除を省略するか
# REPLY: null
# return: null
#
# example:
#  true
#  z.t.expect.status.is.true
#  # 結果: 検証成功（失敗件数は増えない）
z.t.expect.status.is.true() {
  z.t.expect.status true $1 # 変数に格納した時点で$?が変わるので、$1を直接渡す
}
