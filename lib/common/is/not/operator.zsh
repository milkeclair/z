# 2つの値が等しくないか確認する
#
# $1: 基準値
# $2: 比較する値
# REPLY: null
# return: 0|1
#
# example:
#  z.is.not.eq "a" "b"
#  # return: 0
#  z.is.not.eq 1 2
#  # return: 0
#  z.is.not.eq "" "a"
#  # return: 0
z.is.not.eq() {
  local base=$1
  local other=$2

  [[ $base != $other ]]
}

# 指定した値がnullでないか確認する
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.is.not.null "a"
#  # return: 0
#  z.is.not.null 0
#  # return: 0
z.is.not.null() {
  local value=$1

  [[ -n $value ]]
}
