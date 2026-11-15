# call the original function within a mock
#
# $name: function name
# REPLY: null
# return: null
#
# example:
#  z.t.mock.call_original name=my_func
z.t.mock.call_original() {
  z.arg.named name $@ && local name=$REPLY

  z.t.mock name=$name behavior=call_original
}
