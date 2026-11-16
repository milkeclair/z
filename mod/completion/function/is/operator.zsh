# zの関数名が非公開か確認する
#
# $1: 関数名
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.function.is._private z.completion.cache._build
z.completion.function.is._private() {
  local function_name=$1

  z.str.includes "$function_name" "._"
}
