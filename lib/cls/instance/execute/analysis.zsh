# 復元済みの属性について、値とスカラー・配列の形式を保って取得する。
#
# $1: 属性名
# REPLY: 元の形式を保ったスカラーまたは配列の値
# return: 0|1
#
# example:
#  local -a items=(one "two words")
#  z.cls.instance.execute._get items
#  # REPLY: ("one" "two words")
#  # return: 0
z.cls.instance.execute._get() {
  z.is.not.eq "$#" 1 && return 1

  case ${(tP)1} in
    array*|association*) REPLY=("${(@P)1}") ;;
    *) REPLY=${(P)1} ;;
  esac
}
