for indent_file in ${z_root}/lib/io/warn/indent/*.zsh; do
  source $indent_file
done

# printing provided arguments to standard output in provided color
#
# $color: color name (default: yellow)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.warn.color color=yellow "warn message"
z.io.warn.color() {
  local args=($@)

  z.arg.named color default=yellow $args && local color=$REPLY
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
#  z.io.warn.line "warn1" "warn2"
z.io.warn.line() {
  z.is_null $1 && z.io.line "" && return 0

  z.arr.join.line "$@"
  z.str.color.yellow $REPLY
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
#  z.io.warn.indent level=2 "warn message" #=> "    warn message"
z.io.warn.indent() {
  z.arg.named level $@ && local level=$REPLY
  z.arg.named.shift level $@
  local -a args=($REPLY)

  z.str.indent level=$level message="${args[*]}"
  z.io.warn $REPLY
}
