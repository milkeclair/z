# remove named argument from arguments
#
# $1: name of the argument (e.g. option)
# $@: arguments
# REPLY: arguments without the named argument
# return: null
#
# example:
#  z.arg.named.shift option option=value other_arg
#  REPLY="other_arg"
z.arg.named.shift() {
  local name=$1
  shift 2>/dev/null
  local args=($@)
  local result=()
  local arg_count=${#args[@]}
  local i=1

  while z.int.is.lteq $i $arg_count; do
    if z.is.not.null $args[i] && z.str.includes $args[i] $name=; then
      ((i++)) && continue
    fi

    result+=($args[i])
    ((i++))
  done

  z.return ${result[@]}
}
