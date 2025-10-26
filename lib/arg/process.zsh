# argument value as one of the aliases
#
# $name: target argument
# $as: aliases (| separated)
# $return: return value when matched (optional)
# REPLY: $return|null
# return: null
#
# example:
#  z.arg.as name=$1 as="-h|--help" return=0 #=> REPLY=0
#  z.arg.as name=$1 as="--version|-v" return=1 #=> REPLY=1
#  z.arg.as name=$1 as="-h|--help" #=> REPLY=""
z.arg.as() {
  local -a args=($@)
  z.arg.named name $args && local name=$REPLY
  z.arg.named.shift name $args && args=($REPLY)
  z.arg.named as $args && local as=$REPLY
  z.arg.named.shift as $args && args=($REPLY)
  z.arg.named return $args && local return=$REPLY

  z.str.split str=$as
  local -a split_as=($REPLY[@])
  local matched=false

  for alias in $split_as; do
    z.eq $name $alias && matched=true
  done

  z.eq $matched true &&
    z.return $return || z.return
}

# get named argument value
#
# $1: name of the argument (e.g., --option)
# $@: arguments
# REPLY: value of the named argument|null
# return: null
#
# example:
#  z.arg.named option option=value other_arg
#  REPLY="value"
z.arg.named() {
  local name=$1
  shift 2>/dev/null
  local -a args=($@)
  local -i arg_count=${#args[@]}
  local -i i=1

  while ((i <= arg_count)); do
    if z.is_not_null $args[i] && z.str.include $args[i] $name=; then
      z.return ${args[i]#${name}=} && return
    fi

    ((i++))
  done

  z.return
}

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

  while ((i <= arg_count)); do
    if z.is_not_null $args[i] && z.str.include $args[i] $name=; then
      ((i++)) && continue
    fi

    result+=($args[i])
    ((i++))
  done

  z.return ${result[@]}
}
