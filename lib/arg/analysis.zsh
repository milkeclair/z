# get the argument at the specified index (1-based)
#
# $index: 1-based index
# $@: arguments
# REPLY: specified argument|null
# return: null
#
# example:
#  z.arg.get "a" "b" "c" index=2 #=> "b"
z.arg.get() {
  z.arg.named index $@ && local index=$REPLY
  z.arg.named.shift index $@
  local args=($REPLY)
  z.arr.count $args

  z.int.lteq $index $REPLY && z.return $args[$index] || z.return
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
  z.arg.get $@ index=1
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
  z.arg.get $@ index=2
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
  z.arg.get $@ index=3
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

  z.arg.get $@ index=$REPLY
}
