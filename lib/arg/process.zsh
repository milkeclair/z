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
  emulate -L zsh
  local z_arg_parse_option z_arg_parse_key z_arg_parse_name
  local -A z_arg_parse_targets=()

  for z_arg_parse_option in "$@"; do
    case $z_arg_parse_option in
    input=*|named=*|rest=*)
      z_arg_parse_key=${z_arg_parse_option%%=*}
      if (( ${+z_arg_parse_targets[$z_arg_parse_key]} )); then
        print -u2 -- "z.arg.parse: duplicate API argument: $z_arg_parse_key"
        return 1
      fi
      z_arg_parse_targets[$z_arg_parse_key]=${z_arg_parse_option#*=}
      ;;
    *)
      print -u2 -- "z.arg.parse: expected input=, named= and rest= variable names"
      return 1
      ;;
    esac
  done

  local z_arg_parse_input=${z_arg_parse_targets[input]}
  local z_arg_parse_named=${z_arg_parse_targets[named]}
  local z_arg_parse_rest=${z_arg_parse_targets[rest]}

  for z_arg_parse_name in "$z_arg_parse_input" "$z_arg_parse_named" "$z_arg_parse_rest"; do
    if [[ -z $z_arg_parse_name || $z_arg_parse_name == [0-9]* ||
      $z_arg_parse_name == *[^a-zA-Z0-9_]* || $z_arg_parse_name == z_arg_parse_* ]]; then
      print -u2 -- "z.arg.parse: invalid or reserved variable name: $z_arg_parse_name"
      return 1
    fi
  done

  if [[ $z_arg_parse_input == $z_arg_parse_named ||
    $z_arg_parse_input == $z_arg_parse_rest || $z_arg_parse_named == $z_arg_parse_rest ||
    $z_arg_parse_named == REPLY || $z_arg_parse_rest == REPLY ]]; then
    print -u2 -- "z.arg.parse: use distinct variables and output names other than REPLY"
    return 1
  fi

  if [[ ${(Pt)z_arg_parse_input} != array* ||
    ${(Pt)z_arg_parse_input} == *special* ||
    ( ${(Pt)z_arg_parse_named} != association && ${(Pt)z_arg_parse_named} != association-local ) ||
    ( ${(Pt)z_arg_parse_rest} != array && ${(Pt)z_arg_parse_rest} != array-local ) ]]; then
    print -u2 -- "z.arg.parse: input/rest must be indexed arrays and named a writable associative array"
    return 1
  fi

  local -a z_arg_parse_values=("${(@P)z_arg_parse_input}")
  local -A z_arg_parse_result=("${(@Pkv)z_arg_parse_named}")
  local -A z_arg_parse_found=()
  local -a z_arg_parse_remaining=()
  local z_arg_parse_value

  for z_arg_parse_value in "${z_arg_parse_values[@]}"; do
    z_arg_parse_key=${z_arg_parse_value%%=*}
    if [[ $z_arg_parse_value == *=* && -n $z_arg_parse_key ]] &&
      (( ${+z_arg_parse_result[$z_arg_parse_key]} )); then
      if (( ! ${+z_arg_parse_found[$z_arg_parse_key]} )); then
        z_arg_parse_found[$z_arg_parse_key]=${z_arg_parse_value#*=}
      fi
    else
      z_arg_parse_remaining+=("$z_arg_parse_value")
    fi
  done

  local REPLY
  # z.returnが使うargは、変換中だけローカルに隔離する。
  () {
    local arg
    for z_arg_parse_key in "${(@k)z_arg_parse_result}"; do
      if (( ${+z_arg_parse_found[$z_arg_parse_key]} )); then
        z.return "${z_arg_parse_found[$z_arg_parse_key]}"
        if [[ -z $REPLY ]]; then
          z.return ${z_arg_parse_result[$z_arg_parse_key]}
        fi
      else
        z.return ${z_arg_parse_result[$z_arg_parse_key]}
      fi
      z_arg_parse_result[$z_arg_parse_key]=$REPLY
    done
  }

  set -A "$z_arg_parse_named" "${(@kv)z_arg_parse_result}"
  set -A "$z_arg_parse_rest" "${z_arg_parse_remaining[@]}"
}
