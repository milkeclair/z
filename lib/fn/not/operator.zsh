# 関数が存在しないか確認する
#
# $1: 関数名
# REPLY: null
# return: 0|1
#
# example:
#  # my_funcが未登録の場合
#  z.fn.not.exists my_func
#  # return: 0
z.fn.not.exists() {
  z.fn._ensure_store

  local name=$1

  z.fn.exists $name && return 1

  return 0
}
