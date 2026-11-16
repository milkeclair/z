# 値が整数でないか確認する
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.not.match "123"
#  # return: 1
#  z.int.is.not.match "abc"
#  # return: 0
z.int.is.not.match() {
  local value=$1

  [[ $value != <-> && $value != -<-> && $value != +<-> ]]
}

# 2つの整数を比較する（等しくない）
#
# $1: 基準値
# $2: 比較する値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.not.eq 123 456
#  # return: 0
#  z.int.is.not.eq 123 123
#  # return: 1
z.int.is.not.eq() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a != b ))
}

# 値が0でないか確認する
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.not.zero 123
#  # return: 0
#  z.int.is.not.zero 0
#  # return: 1
z.int.is.not.zero() {
  local value=$1

  z.int.is.match $value || return 1

  z.is.not.eq $value 0
}
