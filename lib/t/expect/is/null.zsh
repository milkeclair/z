# 実際の値がnullであることを検証する（空文字列）
#
# $1: 実際の値
# REPLY: null
# return: null
#
# example:
#  z.t.expect.is.null $actual
z.t.expect.is.null() {
  local actual=$1
  z.t.expect $actual ""
}
