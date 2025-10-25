# call the original function within a mock
#
# $1: function name
# REPLY: null
# return: null
#
# example:
#  z.t.mock.call_original my_func
z.t.mock.call_original() {
  z.t.mock $1 "call_original"
}
