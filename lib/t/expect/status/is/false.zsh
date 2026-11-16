# 直前のコマンドの終了コードがfalse（1）であることを検証する
#
# $1?: モック解除を省略するか
# REPLY: null
# return: null
#
# example:
#  some_command
#  z.t.expect.status.is.false
z.t.expect.status.is.false() {
  z.t.expect.status false $1 # 変数に格納した時点で$?が変わるので、$1を直接渡す
}
