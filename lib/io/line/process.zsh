for indent_file in ${z_root}/lib/io/line/indent/*.zsh; do
  source $indent_file
done

# printing provided arguments line by line in provided color
#
# $1: color name
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.line.color red "hello" "world"
z.io.line.color() {
  local color=$1
  shift

  z.is_null $1 && z.io.line "" && return 0

  z.arr.join.line $@
  z.str.color.decorate color=$color message=$REPLY
  z.io.line $REPLY
}

# printing provided arguments line by line with indentation
#
# $level: indent level (number of 2-space indents)
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.io.line.indent level=2 "hello" "world"
z.io.line.indent() {
  z.arg.named level $@ && local level=$REPLY
  z.arg.named.shift level $@
  local args=($REPLY)

  z.arr.count $args
  if z.int.eq $REPLY 0; then
    args=("")
  fi

  local indented=()
  for arg in "${args[@]}"; do
    z.str.indent level=$level message=$arg
    indented+=($REPLY)
  done

  z.io.line "${indented[@]}"
}
