for indent_file in ${z_root}/lib/io/error/indent/*.zsh; do
  source $indent_file
done

# printing provided arguments to stderr in provided color
#
# $color: color name (default: red)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.error.color color=red "error message"
z.io.error.color() {
  local args=($@)

  z.arg.named color default=red $args && local color=$REPLY
  z.arg.named.shift color $args && args=($REPLY)

  z.arr.count $args
  z.int.eq $REPLY 0 && return 0

  z.str.color.decorate color=$color message="${args[*]}"
  print -u2 -- $REPLY
}

# printing provided arguments line by line to stderr
#
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.error.line "error1" "error2"
z.io.error.line() {
  z.is_null $1 && print -u2 -l -- "" && return 0

  z.arr.join.line "$@"
  z.str.color.red $REPLY
  print -u2 -l -- $REPLY
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
  local args=($REPLY)

  z.str.indent level=$level message="${args[*]}"
  z.io.error $REPLY
}
