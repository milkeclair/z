# 名前を指定して変数の値を取得する
#
# $1: 変数名
# REPLY: 変数の値の配列。未宣言なら空
# return: null
#
# example:
#  local TEST_VAR="Hello, World!"
#  z.var.get TEST_VAR
#  # REPLY: "Hello, World!"
z.var.get() {
  if z.var.exists "$1"; then
    REPLY=("${(@P)1}")
  else
    REPLY=()
  fi
}
