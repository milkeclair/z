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

# parse an input array into named values and remaining literal arguments
#
# $input: name of an indexed input array
# $named: name of a writable associative array with accepted names and defaults
# $rest: name of a writable indexed array for remaining arguments
# REPLY: null
# return: 0 on success, 1 for missing arrays or invalid array types
#
# Use distinct array names, separate from REPLY and this function's locals.
# The first occurrence wins; all occurrences of accepted names are removed.
# Named values use z.return conversion; an empty value uses its default.
# Remaining arguments and the input array retain their literal values.
#
# example:
#  local -a input_args=("a" "delimiter=," "b")
#  local -A parsed_named=([delimiter]=" ")
#  local -a parsed_args=()
#  z.arg.parse input=input_args named=parsed_named rest=parsed_args
#  # parsed_named[delimiter]=","; parsed_args=("a" "b")
z.arg.parse() {
  local arg
  z.arg.named input $@ && local input_name=$REPLY
  z.arg.named named $@ && local named_name=$REPLY
  z.arg.named rest $@ && local rest_name=$REPLY

  z.guard; {
    if z.str.is.not.match "${(Pt)input_name}" '^array' ||
      z.str.includes "${(Pt)input_name}" special ||
      z.str.is.not.match "${(Pt)named_name}" '^association(-local)?$' ||
      z.str.is.not.match "${(Pt)rest_name}" '^array(-local)?$'; then
      z.io.error "z.arg.parse: input/rest must be arrays and named an associative array"
      return 1
    fi
  }

  local args=("${(@P)input_name}")
  local -A values=("${(@Pkv)named_name}")
  local remaining=()
  local names=()
  local -A found=()
  local name

  for name in "${(@k)values}"; do
    z.is.null "$name" && continue
    z.str.includes "$name" "=" && continue
    names+=("$name")
  done

  for arg in "${args[@]}"; do
    for name in "${names[@]}"; do
      if z.str.start_with "$arg" "${name}="; then
        if ! z.is.true ${found[$name]}; then
          z.str.remove.prefix "$arg" "${name}="
          z.is.null "$REPLY" && z.return "${values[$name]}"
          values[$name]=$REPLY
          found[$name]=true
        fi
        continue 2
      fi
    done

    remaining+=("$arg")
  done

  for name in "${(@k)values}"; do
    z.is.true ${found[$name]} && continue
    z.return "${values[$name]}"
    values[$name]=$REPLY
  done

  set -A "$named_name" "${(@kv)values}"
  set -A "$rest_name" "${remaining[@]}"
  z.return
}
