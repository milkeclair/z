# 定義済みの関数をすべて一覧し、定義元のファイルを表示する
#
# REPLY: null
# return: null
#
# example:
#  z.fn.list
z.fn.list() {
  z.fn._ensure_store

  local name

  z.hash.keys z_fn_set
  for name in $REPLY; do
    z.io $name
    z.io "Defined in ${z_fn_source[$name]}" indent=1
  done
}

# 登録済み関数の定義を表示する
#
# $1: 関数名
# REPLY: null
# return: null
#
# example:
#  z.fn.show my_func
z.fn.show() {
  z.fn._ensure_store

  local name=$1

  if z.fn.not.exists $name; then
    z.io.error "Function $name does not exist."
    return 1
  fi

  z.io "Defined in: ${z_fn_source[$name]}"
  z.io $(which ${z_fn_set[$name]})
}
