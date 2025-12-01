# expect that actual is null (empty string)
#
# $1: actual value
# REPLY: null
# return: null
#
# example:
#  z.t.expect.is.null $actual
z.t.expect.is.null() {
  local actual=$1
  z.t.expect $actual ""
}
