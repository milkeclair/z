# 関数が存在するか確認する
#
# $1: 関数名
# REPLY: null
# return: 0|1
#
# example:
#  # my_funcが未登録の場合
#  z.fn.exists my_func
#  # return: 1
z.fn.exists() {
  z.fn._ensure_store

  local name=$1
  local key

  z.hash.keys z_fn_set
  for key in $REPLY; do
    z.is.eq $key $name && return 0
  done

  return 1
}
