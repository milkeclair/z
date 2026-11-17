# 文字列をシェルの単語として引用する
#
# $1: 引用する文字列
# $style?: 引用方式（backslash|single|double|ansi、既定: backslash）
# REPLY: 引用した文字列
# return: 0|1
#
# example:
#  z.str.quote "a b" style=ansi
#  # REPLY: "$'a b'"
z.str.quote() {
  z.int.is.gteq $# 1 || return 1
  local value=$1
  shift
  z.arg.named style "$@" default=backslash && local style=$REPLY

  z.arr.quote "style=$style" "$value" || return 1
  REPLY=$REPLY[1]
}

# 単語の引用を一段解除する（変数展開やコマンド実行は行わない）
#
# $1: 引用を解除する単語。未完の引用もZshのQと同じ規則で扱う
# REPLY: 引用を解除した文字列
# return: 0|1
#
# example:
#  z.str.unquote "'a b'"
#  # REPLY: "a b"
z.str.unquote() {
  z.int.is.eq $# 1 || return 1
  local value=$1

  REPLY=${(Q)value}
}
