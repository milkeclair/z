# check if two arrays are equal
#
# $1: first array (as a single string with spaces)
# $2: second array (as a single string with spaces)
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.eq "apple banana cherry" "apple banana cherry"  #=> 0 (true)
#  z.arr.eq "apple banana cherry" "apple grape cherry"  #=> 1 (false)
z.arr.eq() {
  local arr1=($1)
  local arr2=($2)

  z.arr.count $arr1
  local count1=$REPLY
  z.arr.count $arr2
  local count2=$REPLY

  z.int.not_eq $count1 $count2 && return 1

  for ((i=1; i<=count1; i++)); do
    z.not_eq $arr1[i] $arr2[i] && return 1
  done

  return 0
}

# check if two arrays are not equal
#
# $1: first array (as a single string with spaces)
# $2: second array (as a single string with spaces)
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.not_eq "apple banana cherry" "apple banana cherry"  #=> 1 (false)
#  z.arr.not_eq "apple banana cherry" "apple grape cherry"  #=> 0 (true)
z.arr.not_eq() {
  local arr1=($1)
  local arr2=($2)

  z.arr.count $arr1
  local count1=$REPLY
  z.arr.count $arr2
  local count2=$REPLY

  z.int.not_eq $count1 $count2 && return 0

  for ((i=1; i<=count1; i++)); do
    z.not_eq $arr1[i] $arr2[i] && return 0
  done

  return 1
}

# check if array includes element
#
# $target: element to find
# $@: array elements
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.include target=apple "banana" "apple" "cherry"  #=> 0 (true)
#  z.arr.include target=grape "banana" "apple" "cherry"  #=> 1 (false)
z.arr.include() {
  z.arg.named target $@ && local target=$REPLY
  z.arg.named.shift target $@
  local list=($REPLY)

  for item in ${list[@]}; do
    z.eq $item $target && return 0
  done

  return 1
}

# check if array excludes element
#
# $target: element to exclude
# $@: array elements
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.exclude target=apple "banana" "apple" "cherry"  #=> 1 (false)
#  z.arr.exclude target=grape "banana" "apple" "cherry"  #=> 0 (true)
z.arr.exclude() {
  z.arg.named target $@ && local target=$REPLY
  z.arg.named.shift target $@
  local list=($REPLY)

  for item in ${list[@]}; do
    z.eq $item $target && return 1
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
#  z.arr.true_all "1" "2" "3" operation="z.int.is_positive arg"  #=> 0 (true)
#  z.arr.true_all "1" "-2" "3" operation="z.int.is_positive arg"  #=> 1 (false)
z.arr.true_all() {
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
#  z.arr.false_all "-1" "-2" "-3" operation="z.int.is_positive arg"  #=> 0 (true)
#  z.arr.false_all "-1" "2" "-3" operation="z.int.is_positive arg"  #=> 1 (false)
z.arr.false_all() {
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
