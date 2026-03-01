# check if two arrays are equal
#
# $1: first array (as a single string with spaces)
# $2: second array (as a single string with spaces)
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.is.eq "apple banana cherry" "apple banana cherry"  #=> 0 (true)
#  z.arr.is.eq "apple banana cherry" "apple grape cherry"  #=> 1 (false)
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

# check if all array elements satisfy a condition
#
# $operation: operation to evaluate for each element (use 'arg' as placeholder for element)
# $@: array elements
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.is.all_true "1" "2" "3" operation="z.int.is_positive arg"  #=> 0 (true)
#  z.arr.is.all_true "1" "-2" "3" operation="z.int.is_positive arg"  #=> 1 (false)
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

# check if all array elements do not satisfy a condition
#
# $operation: operation to evaluate for each element (use 'arg' as placeholder for element)
# $@: array elements
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.is.all_false "-1" "-2" "-3" operation="z.int.is_positive arg"  #=> 0 (true)
#  z.arr.is.all_false "-1" "2" "-3" operation="z.int.is_positive arg"  #=> 1 (false)
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
