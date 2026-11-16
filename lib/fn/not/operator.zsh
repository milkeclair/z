# 関数が存在しないか確認する
#
# $1: 関数名
# REPLY: null
# 0|1を返す
#
# example:
#  if z.fn.not.exists my_func
z.fn.not.exists() {
  z.fn._ensure_store

  local name=$1

  z.fn.exists $name && return 1

  return 0
}
