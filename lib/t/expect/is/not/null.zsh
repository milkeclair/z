# expect that actual is not null (not empty string)
#
# $1: actual value
# REPLY: null
# return: null
#
# example:
#  z.t.expect.is.not.null $actual
z.t.expect.is.not.null() {
  local actual=$1
  z.t.expect.not $actual ""
}
