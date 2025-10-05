# join array elements with a space
#
# $1: array elements
# REPLY: joined string
# return: null
#
# example:
#  z.arr.join "a" "b" "c" #=> REPLY="a b c"
z.arr.join() {
  local -a arr=($@)

  z.return "${(j: :)arr}"
}
