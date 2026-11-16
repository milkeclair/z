# 連想配列のキーを取得する
#
# $1: 連想配列名
# REPLY: キーの配列
# return: null
#
# example:
#  local -A hash=(name "John")
#  z.hash.keys hash
#  # REPLY: ("name")
z.hash.keys() {
  local hash_name=$1

  REPLY=("${(@Pk)hash_name}")
}

# 連想配列の値を取得する
#
# $1: 連想配列名
# REPLY: 値の配列
# return: null
#
# example:
#  local -A hash=(name "John")
#  z.hash.values hash
#  # REPLY: ("John")
z.hash.values() {
  local hash_name=$1

  REPLY=("${(@Pv)hash_name}")
}

# 連想配列の要素をキーと値の組で取得する
#
# $1: 連想配列名
# REPLY: キーと値の組の配列
# return: null
#
# example:
#  local -A hash=(name "John")
#  z.hash.entries hash
#  # REPLY: ("name" "John")
z.hash.entries() {
  local hash_name=$1

  REPLY=("${(@Pkv)hash_name}")
}

# 連想配列の要素数を数える
#
# $1: 連想配列名
# REPLY: エントリ数
# return: null
#
# example:
#  local -A hash=(name "John" age "30")
#  z.hash.count hash
#  # REPLY: 2
z.hash.count() {
  local hash_name=$1
  local -A hash_ref=("${(@Pkv)hash_name}")

  REPLY=${#hash_ref}
}
