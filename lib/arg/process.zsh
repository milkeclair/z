for named_file in ${z_root}/lib/arg/named/*.zsh; do
  source ${named_file}
done

# argument value as one of the aliases
#
# $name: target argument
# $as: aliases (| separated)
# $return?: return value when matched
# REPLY: $return|null
# return: null
#
# example:
#  z.arg.as name=$1 as="-h|--help" return=0 #=> REPLY=0
#  z.arg.as name=$1 as="--version|-v" return=1 #=> REPLY=1
#  z.arg.as name=$1 as="-h|--help" #=> REPLY=""
z.arg.as() {
  local args=($@)
  z.arg.named name $args && local name=$REPLY
  z.arg.named.shift name $args && args=($REPLY)
  z.arg.named as $args && local as=$REPLY
  z.arg.named.shift as $args && args=($REPLY)
  z.arg.named return $args && local return=$REPLY

  z.str.split str=$as
  local split_as=($REPLY[@])
  local matched=false

  for alias in $split_as; do
    z.is.eq $name $alias && matched=true
  done

  z.is.eq $matched true &&
    z.return $return || z.return
}

# get named argument value
#
# $1: name of the argument (e.g., --option)
# $default?: default value when the named argument is not found
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
  local args=($@)

  z.group "extract default value and filter arguments"; {
    local default=""
    local filtered_args=()
    for arg in $args; do
      if z.str.includes $arg "default="; then
        default=${arg#"default="}
      else
        filtered_args+=($arg)
      fi
    done

    args=($filtered_args)
  }

  z.arr.count $args
  local arg_count=$REPLY
  local i=1

  while z.int.is.lteq $i $arg_count; do
    if z.is.not.null $args[i] && z.str.includes $args[i] $name=; then
      local value=${args[i]#"${name}="}

      z.return ${value:-$default} && return 0
    fi

    ((i++))
  done

  z.return $default
}
