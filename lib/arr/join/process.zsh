# joining array elements with newline
#
# $@: array elements
# REPLY: joined string
# return: null
#
# example:
#  z.arr.join.line "a" "b" "c" #=> REPLY=$'a\nb\nc'
z.arr.join.line() {
  local -a arr=($@)

  z.return ${(pj:\n:)arr}
}
