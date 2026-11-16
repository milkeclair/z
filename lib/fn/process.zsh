# 関数を登録する
# 名前空間への影響を避ける
#
# $1: 関数名
# $2: 関数本体
# REPLY: null
# return: null
#
# example:
#  z.fn my_func 'z.io "Hello, World!"'
z.fn() {
  z.fn._ensure_store

  local name=$1
  local body="$2"
  local hash=$(uuidgen)
  z.str.gsub str="$hash" search="-" replace=""
  local key="z_fn_${REPLY}"

  if z.fn.exists $name; then
    z.io.error "Function $name already exists."
    return 1
  fi

  functions[$key]="$body"
  z_fn_set[$name]=$key
  z_fn_source[$name]=$PWD
}

# 登録済みの関数を呼び出す
#
# $1: 関数名
# $@?: 関数の引数
# REPLY: 関数の返す値
# return: 関数の終了コード
#
# example:
#  z.fn.call my_func arg1 arg2
z.fn.call() {
  z.fn._ensure_store

  local name=$1
  shift

  if z.fn.not.exists $name; then
    z.io.error "Function $name does not exist."
    return 1
  fi

  ${z_fn_set[$name]} "$@"
}

# 登録済み関数を削除する
#
# $1: 関数名
# REPLY: null
# return: null
#
# example:
#  z.fn.delete my_func
z.fn.delete() {
  z.fn._ensure_store

  local name=$1

  if z.fn.not.exists $name; then
    z.io.error "Function $name does not exist."
    return 1
  fi

  local key=${z_fn_set[$name]}

  unfunction $key
  unset "z_fn_set[$name]"
  unset "z_fn_source[$name]"
}

# 登録済み関数をすべて削除する
#
# REPLY: null
# return: null
#
# example:
#  z.fn.delete_all
z.fn.delete_all() {
  z.fn._ensure_store

  z.hash.values z_fn_set
  for value in $REPLY; do
    unfunction $value
  done

  z_fn_set=()
  z_fn_source=()
}

# 登録済みの関数を編集する
#
# $1: 関数名
# $2: 新しい関数本体
# REPLY: null
# return: null
#
# example:
#  z.fn.edit my_func 'z.io "New Body"'
z.fn.edit() {
  z.fn._ensure_store

  local name=$1
  local new_body="$2"
  local hash=$(uuidgen)
  z.str.gsub str=$hash search="-" replace=""
  local key="z_fn_${REPLY}"

  if z.fn.not.exists $name; then
    z.io.error "Function $name does not exist."
    return 1
  fi

  local old_key=${z_fn_set[$name]}
  unfunction $old_key
  functions[$key]="$new_body"
  z_fn_set[$name]=$key
  z_fn_source[$name]=$PWD
}

# 関数の保存領域が初期化されていることを保証する
#
# REPLY: null
# return: null
#
# example:
#  z.fn._ensure_store
z.fn._ensure_store() {
  z.var.exists z_fn_set || typeset -gA z_fn_set
  z.var.exists z_fn_source || typeset -gA z_fn_source
}
