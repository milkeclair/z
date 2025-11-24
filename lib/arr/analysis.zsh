# count the number of elements in an array
#
# $@: array elements
# REPLY: number of elements
# return: null
#
# example:
#  z.arr.count "a" "b" "c" #=> REPLY=3
z.arr.count() {
  local list=("$@")

  z.return ${#list[@]}
}
