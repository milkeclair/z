# printing provided arguments in one line without newline at the end to standard output
#
# $@: arguments
# $color?: color name
# $indent?: indent level
# REPLY: null
# return: null
#
# example:
#  z.io.success.oneline "success message"
z.io.success.oneline() {
  z.arg.named color $@ default=green && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.is_not_null $indent && z.str.indent level=$indent message="$args" && args=($REPLY)
  z.is_not_null $color && z.str.color.decorate color=$color message="$args" && args=($REPLY)

  z.io.oneline $args
}

# printing provided arguments line by line to standard output
#
# $@: arguments
# $color?: color name
# $indent?: indent level
# REPLY: null
# return: null
#
# example:
#  z.io.success.line "success1" "success2"
z.io.success.line() {
  z.arg.named color $@ default=green && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY
  local args=($REPLY)

  z.guard; {
    z.is_null $args && return
  }

  local lines=()
  for arg in $args; do
    local line=$arg
    z.is_not_null $indent && z.str.indent level=$indent message="$line" && line=$REPLY
    lines+=($line)
  done

  z.arr.join.line $lines
  local message=$REPLY
  z.is_not_null $color && z.str.color.decorate color=$color message="$message" && message=$REPLY

  print -- $message
}
