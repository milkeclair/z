# collect remaining arguments and update the parser's named values
# values and accepted_names are scoped by z.arg.parse
#
# $@: input arguments
# REPLY: array of remaining arguments
# return: null
#
# example:
#  z.arg.parse._collect "${args[@]}"
z.arg.parse._collect() {
  local remaining=()
  local -A found=()
  local arg name

  for arg in "$@"; do
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

  REPLY=("${remaining[@]}")
}
