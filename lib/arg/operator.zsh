# check if there is any argument
#
# $@: target values
# REPLY: null
# return: 0|1
#
# example:
#  z.arg.has_any "a" "b" "c" #=> 0
#  z.arg.has_any             #=> 1
z.arg.has_any() {
  local -a args=($@)

  z.int.gt $#args 0
}

# check if there is no argument
#
# $@: target values
# REPLY: null
# return: 0|1
#
# example:
#  z.arg.has_not_any "a" "b" "c" #=> 1
#  z.arg.has_not_any             #=> 0
z.arg.has_not_any() {
  local -a args=($@)

  z.int.eq $#args 0
}

# validate count of arguments
#
# $length: expected minimum count
# $@: arguments
# REPLY: null
# return: 0|1
#
# example:
#  z.arg.validate length=2 "a" "b" "c" #=> 0
#  z.arg.validate length=4 "a" "b" "c" #=> 1
z.arg.validate() {
  z.arg.named length $@ && local length=$REPLY
  z.arg.named.shift length $@ && local -a args=($REPLY)
  local message="Expected at least $length arguments, but got ${#args}"

  if z.int.lt ${#args} $length; then
    z.eq $z_mode test || z.io.error $message
    return 1
  else
    return 0
  fi
}
