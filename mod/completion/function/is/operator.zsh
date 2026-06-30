# check whether a z function name is private
#
# $1: function name
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.function.is._private z.completion.cache._build
z.completion.function.is._private() {
  local function_name=$1

  z.str.includes "$function_name" "._"
}
