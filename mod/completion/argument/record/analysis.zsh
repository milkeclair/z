# 引数仕様を、文字列を評価せず復元できる1行へ変換する
#
# $@: 仕様の各フィールド
# REPLY: 各フィールドをANSI引用で囲んだ1行
# return: 0
#
# example:
#  z.completion.argument.record._encode named code code
#  # REPLY: "$'named' $'code' $'code'"
z.completion.argument.record._encode() {
  z.arr.quote style=ansi "$@"
  z.arr.join "${REPLY[@]}"
}

# 保存した引数仕様をZshの字句分割と引用解除だけで復元する
#
# $1: 引用した仕様の行
# REPLY: 仕様の各フィールド
# return: 0
#
# example:
#  z.completion.argument.record._decode "'named' 'code' 'code'"
#  # REPLY: ("named" "code" "code")
z.completion.argument.record._decode() {
  z.str.split.shell "$1"
  z.arr.unquote "${REPLY[@]}"
}
