# 値が整数か確認する
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.match "123"
#  # return: 0
#  z.int.is.match "abc"
#  # return: 1
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
#  z.int.is.eq 123 123
#  # return: 0
#  z.int.is.eq 123 456
#  # return: 1
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
#  z.int.is.zero 0
#  # return: 0
#  z.int.is.zero 123
#  # return: 1
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
#  z.int.is.positive 123
#  # return: 0
#  z.int.is.positive 0
#  # return: 1
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
#  z.int.is.negative -123
#  # return: 0
#  z.int.is.negative 123
#  # return: 1
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
#  z.int.is.gt 456 123
#  # return: 0
#  z.int.is.gt 123 123
#  # return: 1
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
#  z.int.is.gteq 123 123
#  # return: 0
#  z.int.is.gteq 123 456
#  # return: 1
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
#  z.int.is.lt 123 456
#  # return: 0
#  z.int.is.lt 123 123
#  # return: 1
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
#  z.int.is.lteq 123 123
#  # return: 0
#  z.int.is.lteq 456 123
#  # return: 1
z.int.is.lteq() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a <= b ))
}

# 値が上下限を含む十進整数の範囲内か確認する
#
# $1: 判定する値。先頭ゼロを許可する
# $min: 下限
# $max: 上限
# $signed?: 値の符号を許可するか（true|false、既定: true）
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.between 3000 min=1 max=65535 signed=false
#  # return: 0
z.int.is.between() {
  z.int.is.gteq $# 1 || return 1
  local value=$1
  shift
  z.arg.named min "$@" && local minimum=$REPLY
  z.arg.named max "$@" && local maximum=$REPLY
  z.arg.named signed "$@" default=true && local signed=$REPLY

  case $signed in
  false)
    if z.str.start_with "$value" "+" || z.str.start_with "$value" "-"; then
      return 1
    fi
    ;;
  true)
    ;;
  *)
    return 1
    ;;
  esac

  # 同値は元の位置で比較されるため、範囲内なら下限・値・上限の順を保つ
  z.arr.sort.numeric by=asc "$minimum" "$value" "$maximum" || return 1
  local ordered=("${REPLY[@]}")

  z.is.eq "$ordered[1]" "$minimum" && z.is.eq "$ordered[3]" "$maximum"
}
