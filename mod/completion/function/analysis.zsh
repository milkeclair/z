# get public z function candidates for a prefix
#
# $1: function name prefix
# REPLY: matching function names|null
# return: 0|1
#
# example:
#  z.completion.function._candidates z.arg.
z.completion.function._candidates() {
  local prefix=$1
  local function_names=("${z_completion_function_names[@]}")

  z.int.is.zero ${#function_names[@]} && return 1

  local candidates=()
  for function_name in $function_names; do
    if z.str.start_with "$function_name" "z." &&
      ! z.completion.function.is._private "$function_name" &&
      z.str.start_with "$function_name" "$prefix"; then
      candidates+=("$function_name")
    fi
  done

  if z.int.is.zero ${#candidates[@]}; then
    return 1
  fi

  z.arr.join.line "${candidates[@]}"
}
