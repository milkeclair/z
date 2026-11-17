# シェルの規則で単語と演算子へ分割し、引用表現を保持する
#
# $1: 分割する文字列
# $comments?: コメントの扱い（literal|keep|drop、既定: literal）
# $newlines?: 引用外の改行の扱い（separator|whitespace、既定: separator）
# REPLY: 単語と演算子の配列
# return: 0|1
#
# example:
#  z.str.split.shell 'print "a b"; next'
#  # REPLY: ("print" '"a b"' ";" "next")
z.str.split.shell() {
  z.int.is.gteq $# 1 || return 1
  local value=$1
  shift
  z.arg.named comments "$@" default=literal && local comments=$REPLY
  z.arg.named newlines "$@" default=separator && local newlines=$REPLY

  case "$comments:$newlines" in
  literal:separator)
    REPLY=("${(@z)value}")
    ;;
  literal:whitespace)
    REPLY=("${(@Z+n+)value}")
    ;;
  keep:separator)
    REPLY=("${(@Z+c+)value}")
    ;;
  keep:whitespace)
    REPLY=("${(@Z+cn+)value}")
    ;;
  drop:separator)
    REPLY=("${(@Z+C+)value}")
    ;;
  drop:whitespace)
    REPLY=("${(@Z+Cn+)value}")
    ;;
  *)
    return 1
    ;;
  esac
}

# LFで行に分割する。空要素の保持時は末尾の空行も返す
#
# $1: 分割する文字列
# $empty?: 空行の扱い（keep|drop、既定: keep）
# REPLY: 行の配列
# return: 0|1
#
# example:
#  z.str.split.line $'a\n\nb\n'
#  # REPLY: ("a" "" "b" "")
z.str.split.line() {
  z.int.is.gteq $# 1 || return 1
  local value=$1
  shift
  z.arg.named empty "$@" default=keep && local empty=$REPLY

  case $empty in
  keep)
    REPLY=("${(@f)value}")
    ;;
  drop)
    REPLY=(${(f)value})
    ;;
  *)
    return 1
    ;;
  esac
}
