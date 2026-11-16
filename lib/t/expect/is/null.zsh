# 実際の値がnullであることを検証する（空文字列）
#
# $1: 実際の値
# REPLY: null
# return: null
#
# example:
#  # 失敗件数0から実行する場合
#  z.t.expect.is.null ""
#  # 変更後の失敗件数: 0
z.t.expect.is.null() {
  local actual=$1
  z.t.expect $actual ""
}
