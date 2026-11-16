# 実際の値がnullでないことを検証する（空文字列でない）
#
# $1: 実際の値
# REPLY: null
# return: null
#
# example:
#  # 失敗件数0から実行する場合
#  z.t.expect.is.not.null "value"
#  # 変更後の失敗件数: 0
z.t.expect.is.not.null() {
  local actual=$1
  z.t.expect.not $actual ""
}
