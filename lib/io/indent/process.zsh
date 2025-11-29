# printing colored and indented message
#
# $level: indent level (number of 2-space indents)
# $color: color name
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.indent.color level=2 color=red "indented message" #=> prints "    indented message" in red color
z.io.indent.color() {
  local args=($@)

  z.arg.named level 0 $args && local level=$REPLY
  z.arg.named.shift level $args && args=($REPLY)
  z.arg.named color $args && local color=$REPLY
  z.arg.named.shift color $args && args=($REPLY)

  z.is_null ${args[1]} && return 0

  z.str.color.decorate color=$color message="${args[*]}"
  z.io.indent level=$level $REPLY
}
