# printing provided arguments in one line without newline at the end to stderr
#
# $@: arguments
# $color?: color name
# $indent?: indent level
# REPLY: null
# return: null
#
# example:
#  z.io.error.oneline "error message"
z.io.error.oneline() {
  z.arg.named color $@ default=red && local color=$REPLY
  z.arg.named indent $@ && local indent=$REPLY
  z.arg.named.shift color $@
  z.arg.named.shift indent $REPLY

  z.is_not_null $indent && z.str.indent level=$indent message="$*"
  z.is_not_null $color && z.str.color.decorate color=$color message="$REPLY"

  print -u2 -n -- $REPLY
}

# printing provided arguments line by line to stderr
#
# $@: arguments
# $color?: color name
# $indent?: indent level
# REPLY: null
# return: null
#
# example:
#  z.io.error.line "error1" "error2"
z.io.error.line() {
  z.arg.named color $@ default=red && local color=$REPLY
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

  print -u2 -- $message
}
