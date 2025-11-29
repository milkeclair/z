for indent_file in ${z_root}/lib/io/success/indent/*.zsh; do
  source $indent_file
done

# printing provided arguments to standard output in provided color
#
# $color: color name (default: green)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.success.color color=green "success message"
z.io.success.color() {
  local args=($@)

  z.arg.named color default=green $args && local color=$REPLY
  z.arg.named.shift color $args && args=($REPLY)

  z.arr.count $args
  z.int.eq $REPLY 0 && return 0

  z.str.color.decorate color=$color message="${args[*]}"
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
  z.is_null $1 && return 0

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
