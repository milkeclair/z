# zの関数名が非公開か確認する
#
# $1: 関数名
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.function.is._private z.completion.cache._build
#  # return: 0
#  z.completion.function.is._private z.arg.get
#  # return: 1
z.completion.function.is._private() {
  local function_name=$1

  z.str.includes "$function_name" "._"
}
