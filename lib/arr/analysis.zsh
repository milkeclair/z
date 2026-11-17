# 配列の要素数を数える
#
# $@: 配列の要素
# REPLY: 要素数
# return: null
#
# example:
#  z.arr.count "a" "b" "c"
#  # REPLY: 3
z.arr.count() {
  local list=("$@")

  REPLY=${#list[@]}
}

# 配列の全要素をシェルの単語として引用する
#
# $style?: 先頭に指定する引用方式（backslash|single|double|ansi、既定: backslash）
# $@: 引用する要素。styleに似た要素は明示的なstyle指定の後ろへ置く
# REPLY: 引用した要素の配列
# return: 0|1
#
# example:
#  z.arr.quote style=ansi "a b" "" "style=double"
#  # REPLY: ("$'a b'" "$''" "$'style=double'")
z.arr.quote() {
  local style=backslash
  if z.str.start_with "${1-}" "style="; then
    z.str.remove.prefix "$1" "style="
    style=$REPLY
    shift
  fi
  local values=("$@")

  case $style in
  backslash)
    REPLY=("${(@q)values}")
    ;;
  single)
    REPLY=("${(@qq)values}")
    ;;
  double)
    REPLY=("${(@qqq)values}")
    ;;
  ansi)
    REPLY=("${(@qqqq)values}")
    ;;
  *)
    return 1
    ;;
  esac
}

# 配列の各要素の引用を一段解除する
#
# $@: 引用を解除する単語。変数展開やコマンド実行は行わない
# REPLY: 引用を解除した要素の配列
# return: 0
#
# example:
#  z.arr.unquote "'a b'" "''"
#  # REPLY: ("a b" "")
z.arr.unquote() {
  local values=("$@")

  REPLY=("${(@Q)values}")
}
