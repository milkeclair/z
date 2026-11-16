# 2つの配列が等しくないか確認する
#
# $1: 1つ目の配列（空白区切りの1つの文字列）
# $2: 2つ目の配列（空白区切りの1つの文字列）
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.is.not.eq "apple banana cherry" "apple banana cherry"  #=> 1 (false)
#  z.arr.is.not.eq "apple banana cherry" "apple grape cherry"  #=> 0 (true)
z.arr.is.not.eq() {
  local arr1=($1)
  local arr2=($2)

  z.arr.count $arr1
  local count1=$REPLY
  z.arr.count $arr2
  local count2=$REPLY

  z.int.is.not.eq $count1 $count2 && return 0

  for ((i=1; i<=count1; i++)); do
    z.is.not.eq $arr1[i] $arr2[i] && return 0
  done

  return 1
}
