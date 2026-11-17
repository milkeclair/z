# ZLEの引数位置で、解析上限内のコード補完を試せるか判定する
#
# REPLY: null
# return: 補完可能なら0、それ以外は1
#
# example:
#  # ZLEでCURRENT=2、words=(run code=print)の場合
#  z.completion.code.is._active
#  # return: 0
z.completion.code.is._active() {
  z.var.exists compstate || return 1
  z.int.is.gt "$CURRENT" 1 || return 1
  z.int.is.lteq "${#words[CURRENT]}" 1048576
}

# コード引数の値が、宣言された許可値と完全に一致するか判定する
#
# $value: 引数の値
# $literals: 許可値の配列名
# REPLY: null
# return: 許可値なら0、それ以外は1
#
# example:
#  local allowed_values=("" "default=x")
#  z.completion.code.is._literal value= literals=allowed_values
#  # return: 0
z.completion.code.is._literal() {
  z.arg.named value "$@" && local value=$REPLY
  z.arg.named literals "$@" && local literals_name=$REPLY
  z.var.get "$literals_name"
  local allowed_values=("${REPLY[@]}")
  local literal

  for literal in "${allowed_values[@]}"; do
    z.is.eq "$value" "$literal" && return 0
  done

  return 1
}
