# 配列の要素を改行で結合する
#
# $@: 配列の要素
# REPLY: 結合した文字列
# return: null
#
# example:
#  z.arr.join.line "a" "b" "c" #=> REPLY=$'a\nb\nc'
z.arr.join.line() {
  local arr=("$@")

  REPLY=${(pj:\n:)arr}
}
