# 実際の値がnullでないことを検証する（空文字列でない）
#
# $1: 実際の値
# REPLY: null
# return: null
#
# example:
#  z.t.expect.is.not.null $actual
z.t.expect.is.not.null() {
  local actual=$1
  z.t.expect.not $actual ""
}
