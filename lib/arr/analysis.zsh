# 配列の要素数を数える
#
# $@: 配列の要素
# REPLY: 要素数
# return: null
#
# example:
#  z.arr.count "a" "b" "c" #=> REPLY=3
z.arr.count() {
  local list=("$@")

  REPLY=${#list[@]}
}
