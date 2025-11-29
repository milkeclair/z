# printing colored and indented arguments to stdout
#
# $level: indent level (number of 2-space indents)
# $color: color name (default: green)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.success.indent.color level=2 color=cyan "success message"
z.io.success.indent.color() {
  local args=($@)

  z.arg.named level 0 $args && local level=$REPLY
  z.arg.named.shift level $args && args=($REPLY)
  z.arg.named color default=green $args && local color=$REPLY
  z.arg.named.shift color $args && args=($REPLY)

  z.arr.count $args
  z.int.eq $REPLY 0 && return 0

  local colored=()
  for arg in "${args[@]}"; do
    z.str.color.decorate color=$color message=$arg
    colored+=($REPLY)
  done

  local indented=()
  for message in "${colored[@]}"; do
    z.str.indent level=$level message=$message
    indented+=($REPLY)
  done

  z.io.line "${indented[@]}"
}
