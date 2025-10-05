# check if two arrays are equal
#
# $1: first array (as a single string with spaces)
# $2: second array (as a single string with spaces)
# REPLY: null
# return 0|1
#
# example:
#  z.arr.eq "apple banana cherry" "apple banana cherry"  #=> 0 (true)
#  z.arr.eq "apple banana cherry" "apple grape cherry"  #=> 1 (false)
z.arr.eq() {
  local -a arr1=($1)
  local -a arr2=($2)

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
# return 0|1
#
# example:
#  z.arr.not_eq "apple banana cherry" "apple banana cherry"  #=> 1 (false)
#  z.arr.not_eq "apple banana cherry" "apple grape cherry"  #=> 0 (true)
z.arr.not_eq() {
  local -a arr1=($1)
  local -a arr2=($2)

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
# $1: element
# $@: array elements
# REPLY: null
# return 0|1
#
# example:
#  z.arr.is_include "apple" "banana" "apple" "cherry"  #=> 0 (true)
#  z.arr.is_include "grape" "banana" "apple" "cherry"  #=> 1 (false)
z.arr.is_include() {
  local element=$1 && shift
  local -a list=($@)

  for item in ${list[@]}; do
    [[ $item == $element ]] && return 0
  done

  return 1
}
