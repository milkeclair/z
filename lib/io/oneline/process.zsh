for indent_file in ${z_root}/lib/io/oneline/indent/*.zsh; do
  source $indent_file
done

# printing provided arguments with color without newline at the end
#
# $1: color name
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.oneline.color red "hello" "world" #=> (prints "hello world" in red color without newline)
z.io.oneline.color() {
  local color=$1
  shift

  z.is_null $1 && return 0

  z.str.color.decorate color=$color message="$*"
  z.io.oneline $REPLY
}

# printing provided arguments with indentation without newline at the end
#
# $level: indent level (number of 2-space indents)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.oneline.indent level=2 "hello" "world" #=> "    hello world" (without newline)
z.io.oneline.indent() {
  z.arg.named level $@ && local level=$REPLY
  z.arg.named.shift level $@
  local -a args=($REPLY)

  z.str.indent level=$level message="${args[*]}"
  z.io.oneline $REPLY
}
