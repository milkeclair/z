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
# $input: name of a declared ordinary indexed array (read only)
# $named: name of a plain writable associative array declaring accepted names and defaults
# $rest: name of a plain writable indexed array for remaining arguments
# REPLY: unchanged
# return: 0 on success, 1 for invalid API arguments or variable declarations
#
# The three variable names must differ. Output names cannot be REPLY.
# Variable names starting with z_arg_parse_ are reserved.
# The first occurrence of each declared name wins; all its occurrences are removed.
# Named values use z.return conversion; an empty converted value uses its default.
# Unknown arguments and empty elements are preserved literally in rest.
# Outputs are unchanged on validation failure. Successful calls print nothing.
#
# example:
#  local -a input_args=("a" "delimiter=," "b")
#  local -A parsed_named=([delimiter]=" ")
#  local -a parsed_args=()
#  z.arg.parse input=input_args named=parsed_named rest=parsed_args
#  # parsed_named[delimiter]=","; parsed_args=("a" "b")
z.arg.parse() {
  local z_arg_parse_input z_arg_parse_named z_arg_parse_rest

  () {
    local REPLY arg name MATCH MBEGIN MEND match mbegin mend
    z.arg.named.literal input "$@" && local input_name=$REPLY
    z.arg.named.literal named "$@" && local named_name=$REPLY
    z.arg.named.literal rest "$@" && local rest_name=$REPLY

    z.guard; {
      z.arr.count "$@"
      if z.int.is.not.eq $REPLY 3; then
        z.io.error "z.arg.parse: input, named and rest are required"
        return 1
      fi

      for name in "$input_name" "$named_name" "$rest_name"; do
        if z.str.is.not.match "$name" '^[a-zA-Z_][a-zA-Z0-9_]*$' ||
          z.str.start_with "$name" "z_arg_parse_"; then
          z.io.error "z.arg.parse: invalid variable name: $name"
          return 1
        fi
      done

      if z.is.eq "$input_name" "$named_name" || z.is.eq "$input_name" "$rest_name" ||
        z.is.eq "$named_name" "$rest_name" || z.is.eq "$named_name" REPLY ||
        z.is.eq "$rest_name" REPLY; then
        z.io.error "z.arg.parse: use distinct input and output variables"
        return 1
      fi
    }

    z_arg_parse_input=$input_name
    z_arg_parse_named=$named_name
    z_arg_parse_rest=$rest_name
  } "$@" || return 1

  () {
    local REPLY arg MATCH MBEGIN MEND match mbegin mend
    if z.str.is.not.match "$1" '^array' || z.str.includes "$1" special ||
      z.str.is.not.match "$2" '^association(-local)?$' ||
      z.str.is.not.match "$3" '^array(-local)?$'; then
      z.io.error "z.arg.parse: input/rest must be arrays and named an associative array"
      return 1
    fi
  } "${(Pt)z_arg_parse_input}" "${(Pt)z_arg_parse_named}" "${(Pt)z_arg_parse_rest}" || return 1

  local -a z_arg_parse_args=("${(@P)z_arg_parse_input}")
  local -A z_arg_parse_values=("${(@Pkv)z_arg_parse_named}")
  local -a z_arg_parse_remaining=()

  () {
    local REPLY arg name
    local names=()
    local -A found=()

    for name in "${(@k)z_arg_parse_values}"; do
      z.is.null "$name" && continue
      z.str.includes "$name" "=" && continue
      names+=("$name")
    done

    for arg in "${z_arg_parse_args[@]}"; do
      for name in "${names[@]}"; do
        if z.str.start_with "$arg" "${name}="; then
          if ! z.is.true ${found[$name]}; then
            z.str.remove.prefix "$arg" "${name}="
            z.is.null "$REPLY" && z.return "${z_arg_parse_values[$name]}"
            z_arg_parse_values[$name]=$REPLY
            found[$name]=true
          fi
          continue 2
        fi
      done

      z_arg_parse_remaining+=("$arg")
    done

    for name in "${(@k)z_arg_parse_values}"; do
      z.is.true ${found[$name]} && continue
      z.return "${z_arg_parse_values[$name]}"
      z_arg_parse_values[$name]=$REPLY
    done
  }

  set -A "$z_arg_parse_named" "${(@kv)z_arg_parse_values}"
  set -A "$z_arg_parse_rest" "${z_arg_parse_remaining[@]}"
}
