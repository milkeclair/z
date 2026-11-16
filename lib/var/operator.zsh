# 変数が存在するか確認する
#
# $1: 変数名
# REPLY: null
# return: 0\1
#
# example:
#   local TEST_VAR="Hello, World!"
#   z.var.exists TEST_VAR
#   echo $?  # outputs 0
z.var.exists() {
  (( ${(P)+1} ))
}

# 変数が定義済みか確認する（宣言と代入が済んでいる）
#
# $1: 変数名
# REPLY: null
# return: 0\1
#
# example:
#   local TEST_VAR="Hello, World!"
#   z.var.sets TEST_VAR
#   echo $?  # outputs 0
z.var.sets() {
  z.var.exists $1 && z.is.not.null ${(P)1}
}
