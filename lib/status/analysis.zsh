# 直前のコマンドの終了コードを取得する
#
# REPLY: 直前のコマンドの終了コード
# return: null
#
# example:
#  false
#  z.status
#  # REPLY: 1
z.status() {
  REPLY=$?
}
