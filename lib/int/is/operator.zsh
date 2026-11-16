# 値が整数か確認する
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.match "123" && z.io "is integer" || z.io "is not integer"
z.int.is.match() {
  local value=$1

  [[ $value == <-> || $value == -<-> || $value == +<-> ]]
}

# 2つの整数を比較する
#
# $1: 基準値
# $2: 比較する値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.eq 123 123 && z.io "equal" || z.io "not equal"
z.int.is.eq() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a == b ))
}

# 値が0か確認する
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.zero 0 && z.io "is zero" || z.io "is not zero"
z.int.is.zero() {
  local value=$1

  z.is.eq $value 0
}

# 値が正か確認する
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.positive 123 && z.io "is positive" || z.io "is not positive"
z.int.is.positive() {
  local value=$1

  z.int.is.gt $value 0
}

# 値が負か確認する
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.negative -123 && z.io "is negative" || z.io "is not negative"
z.int.is.negative() {
  local value=$1

  z.int.is.lt $value 0
}

# 2つの整数を比較する（より大きい）
#
# $1: 基準値
# $2: 比較する値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.gt 456 123 && z.io "greater" || z.io "not greater"
z.int.is.gt() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a > b ))
}

# 2つの整数を比較する（以上）
#
# $1: 基準値
# $2: 比較する値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.gteq 456 123 && z.io "greater or equal" || z.io "not greater or equal"
z.int.is.gteq() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a >= b ))
}

# 2つの整数を比較する（より小さい）
#
# $1: 基準値
# $2: 比較する値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.lt 123 456 && z.io "less" || z.io "not less"
z.int.is.lt() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a < b ))
}

# 2つの整数を比較する（以下）
#
# $1: 基準値
# $2: 比較する値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.lteq 123 456 && z.io "less or equal" || z.io "not less or equal"
z.int.is.lteq() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a <= b ))
}
