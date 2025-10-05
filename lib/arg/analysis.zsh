# get the argument at the specified index (1-based)
#
# $1: index (1-based)
# $@: arguments
# REPLY: specified argument|null
# return: null
#
# example:
#  z.arg.get 2 "a" "b" "c" #=> "b"
z.arg.get() {
  local -i index=$1 && shift
  z.arr.count $@

  z.int.lteq $index $REPLY && z.return $@[$index] || z.return
}

# get the first argument
#
# $@: arguments
# REPLY: first argument|null
# return: null
#
# example:
#  z.arg.first "a" "b" "c" #=> "a"
z.arg.first() {
  z.arg.get 1 $@
}

# get the second argument
#
# $@: arguments
# REPLY: second argument|null
# return: null
#
# example:
#  z.arg.second "a" "b" "c" #=> "b"
z.arg.second() {
  z.arg.get 2 $@
}

# get the third argument
#
# $@: arguments
# REPLY: third argument|null
# return: null
#
# example:
#  z.arg.third "a" "b" "c" #=> "c"
z.arg.third() {
  z.arg.get 3 $@
}

# get the last argument
#
# $@: arguments
# REPLY: last argument|null
# return: null
#
# example:
#  z.arg.last "a" "b" "c" #=> "c"
z.arg.last() {
  z.arr.count $@

  z.arg.get $REPLY $@
}
