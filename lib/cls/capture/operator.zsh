# 現在の実行位置が、定義元のスコープかその内側にあるかを判定する。
#
# $1: 現在の呼出しスタック
# $2: 定義元の呼出しスタック。最上位は空文字列
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.capture._within_scope 'helper|outer' outer
#  # return: 0
#  z.cls.capture._within_scope another outer
#  # return: 1
z.cls.capture._within_scope() {
  # パスや関数名に含まれる記号も、スタックの文字として比較する。
  z.is.null "$2" || [[ "|$1" == *"|$2" ]]
}
