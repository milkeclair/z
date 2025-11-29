# printing colored and indented lines
#
# $level: indent level (number of 2-space indents)
# $color: color name
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.line.indent.color level=2 color=red "hello" "world"
z.io.line.indent.color() {
  local args=($@)

  z.arg.named level 0 $args && local level=$REPLY
  z.arg.named.shift level $args && args=($REPLY)
  z.arg.named color $args && local color=$REPLY
  z.arg.named.shift color $args && args=($REPLY)

  z.arr.count $args
  z.int.eq $REPLY 0 && return 0

  local colored=()
  for arg in "${args[@]}"; do
    z.str.color.decorate color=$color message=$arg
    colored+=($REPLY)
  done

  z.io.line.indent level=$level "${colored[@]}"
}
