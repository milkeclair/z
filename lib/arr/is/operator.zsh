# 2つの配列が等しいか確認する
#
# $1: 1つ目の配列（空白区切りの1つの文字列）
# $2: 2つ目の配列（空白区切りの1つの文字列）
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.is.eq "apple banana cherry" "apple banana cherry"
#  # return: 0
#  z.arr.is.eq "apple banana cherry" "apple grape cherry"
#  # return: 1
z.arr.is.eq() {
  local arr1=($1)
  local arr2=($2)

  z.arr.count $arr1
  local count1=$REPLY
  z.arr.count $arr2
  local count2=$REPLY

  z.int.is.not.eq $count1 $count2 && return 1

  for ((i=1; i<=count1; i++)); do
    z.is.not.eq $arr1[i] $arr2[i] && return 1
  done

  return 0
}

# 配列の全要素が条件を満たすか確認する
#
# $operation: 各要素に適用する処理（要素の代わりに'arg'を使う）
# $@: 配列の要素
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.is.all_true "1" "2" "3" operation="z.int.is.not.zero"
#  # return: 0
#  z.arr.is.all_true "1" "0" "3" operation="z.int.is.not.zero"
#  # return: 1
z.arr.is.all_true() {
  z.arg.named operation $@
  z.arr.gsub $REPLY search="arg" replace="\$item"
  local operation=$REPLY
  z.arg.named.shift operation $@

  local list=($REPLY)

  for item in ${list[@]}; do
    eval "$operation \"$item\"" || return 1
  done

  return 0
}

# 配列の全要素が条件を満たさないか確認する
#
# $operation: 各要素に適用する処理（要素の代わりに'arg'を使う）
# $@: 配列の要素
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.is.all_false "0" "0" "0" operation="z.int.is.not.zero"
#  # return: 0
#  z.arr.is.all_false "0" "2" "0" operation="z.int.is.not.zero"
#  # return: 1
z.arr.is.all_false() {
  z.arg.named operation $@
  z.arr.gsub $REPLY search="arg" replace="\$item"
  local operation=$REPLY
  z.arg.named.shift operation $@

  local list=($REPLY)

  for item in ${list[@]}; do
    eval "$operation \"$item\"" && return 1
  done

  return 0
}
