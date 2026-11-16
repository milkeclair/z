# 直前のコマンドの終了コードを取得する
#
# REPLY: 直前のコマンドの終了コード
# return: null
#
# example:
#  z.status #=> returns the exit status of the last command
z.status() {
  REPLY=$?
}
