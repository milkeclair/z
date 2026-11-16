# 関数が存在するか確認する
#
# $1: 関数名
# REPLY: null
# 0|1を返す
#
# example:
#  if z.fn.exists my_func
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
