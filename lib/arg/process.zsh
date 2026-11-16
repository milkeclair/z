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
  local default=""
  local value=""
  local found=false

  for arg in $args; do
    if z.str.start_with "$arg" "default="; then
      z.str.remove.prefix "$arg" "default="
      default=$REPLY
    elif z.is.false $found && z.str.start_with "$arg" "${name}="; then
      z.str.remove.prefix "$arg" "${name}="
      value=$REPLY
      found=true
    fi
  done

  z.return ${value:-$default}
}

# parse named arguments and collect the remaining arguments
#
# $input: name of the input array (read only)
# $named: name of the hash of defaults, updated with first matching values
# $rest: name of the output array for remaining literal arguments
# REPLY: null
# return: 0 if parsed, otherwise 1
#
# example:
#  local -a input_args=("a" "delimiter=," "b")
#  local -A parsed_named=([delimiter]=" ")
#  local -a parsed_args=()
#  z.arg.parse input=input_args named=parsed_named rest=parsed_args
z.arg.parse() {
  local arg
  z.arg.named input $@ && local input_name=$REPLY
  z.arg.named named $@ && local named_name=$REPLY
  z.arg.named rest $@ && local rest_name=$REPLY

  z.guard; {
    if ! z.var.exists "$input_name" || ! z.var.exists "$named_name" ||
      ! z.var.exists "$rest_name"; then
      z.io.error "z.arg.parse: input, named and rest arrays are required"
      return 1
    fi
  }

  z.var.get $input_name literal=true && local args=("${REPLY[@]}")
  z.hash.entries $named_name literal=true && local -A values=("${REPLY[@]}")
  z.hash.keys values literal=true && local names=("${REPLY[@]}")
  local accepted_names=()
  local remaining=()
  local -A found
  local name

  z.group "preparing defaults"; {
    for name in "${names[@]}"; do
      z.return "${values[$name]}"
      values[$name]=$REPLY

      z.is.null "$name" && continue
      z.str.includes "$name" "=" && continue
      accepted_names+=("$name")
    done
  }

  z.group "parsing arguments"; {
    for arg in "${args[@]}"; do
      local matched=false

      for name in "${accepted_names[@]}"; do
        z.str.start_with "$arg" "${name}=" || continue

        if ! z.is.true ${found[$name]}; then
          z.str.remove.prefix "$arg" "${name}="
          local value=$REPLY
          z.is.null "$value" && value=${values[$name]}
          values[$name]=$value
          found[$name]=true
        fi

        matched=true
        break
      done

      z.is.false $matched && remaining+=("$arg")
    done
  }

  z.group "writing results"; {
    z.hash.entries values literal=true
    set -A "$named_name" "${REPLY[@]}"
    set -A "$rest_name" "${remaining[@]}"
  }

  z.return
}
