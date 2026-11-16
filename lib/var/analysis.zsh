# 名前を指定して変数の値を取得する
#
# $1: 変数名
# REPLY: 変数の値の配列。未宣言なら空
# return: null
#
# example:
#   local TEST_VAR="Hello, World!"
#   z.var.get TEST_VAR
#   echo $REPLY  # outputs "Hello, World!"
z.var.get() {
  local var_name=$1

  if z.var.exists $var_name; then
    REPLY=("${(@P)var_name}")
  else
    REPLY=()
  fi
}
