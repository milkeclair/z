# printing provided arguments line by line to stderr
#
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.error.line "error1" "error2"
z.io.error.line() {
  # $@: print arguments
  # return: null
  print -u2 -l -- $@
}

# printing provided arguments with indentation to stderr
#
# $level: indent level (number of 2-space indents)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.error.indent level=2 "error message" #=> "    error message"
z.io.error.indent() {
  z.arg.named level $@ && local level=$REPLY
  z.arg.named.shift level $@
  local -a args=($REPLY)
  local indent=""

  for ((i=0; i<level; i++)); do
    indent+="  "
  done

  z.io.error "$indent${args[@]}"
}
