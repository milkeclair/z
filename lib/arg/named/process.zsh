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
  local -a args=($@)
  local -a result=()
  local -i arg_count=${#args[@]}
  local -i i=1

  while z.int.lteq $i $arg_count; do
    if z.is_not_null $args[i] && z.str.include $args[i] $name=; then
      ((i++)) && continue
    fi

    result+=($args[i])
    ((i++))
  done

  z.return ${result[@]}
}
