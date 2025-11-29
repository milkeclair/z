# printing provided arguments to standard output in provided color
#
# $1: color name
# $2: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.success.color green "success message"
z.io.success.color() {
  local color=$1
  shift

  z.is_null $1 && return 0

  z.str.color.green "$@"
  z.io $REPLY
}

# printing provided arguments line by line to standard output
#
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.success.line "success1" "success2"
z.io.success.line() {
  z.is_null $1 && z.io.line "" && return 0

  z.arr.join.line "$@"
  z.str.color.green $REPLY
  z.io.line $REPLY
}

# printing provided arguments with indentation to standard output
#
# $level: indent level (number of 2-space indents)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.success.indent level=2 "success message" #=> "    success message"
z.io.success.indent() {
  z.arg.named level $@ && local level=$REPLY
  z.arg.named.shift level $@
  local -a args=($REPLY)

  z.str.indent level=$level message="${args[*]}"
  z.io.success $REPLY
}
