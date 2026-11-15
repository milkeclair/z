# get root namespaces for z. or public function candidates for a deeper prefix
#
# $1: function name prefix
# REPLY: matching namespace or function names|null
# return: 0|1
#
# example:
#  z.completion.function._candidates z.arg.
z.completion.function._candidates() {
  local prefix=$1
  local function_names=("${z_completion_function_names[@]}")

  local candidates=()
  for function_name in $function_names; do
    if z.str.start_with "$function_name" "z." &&
      ! z.completion.function.is._private "$function_name" &&
      z.str.start_with "$function_name" "$prefix"; then
      local candidate=$function_name
      if z.is.eq "$prefix" z.; then
        z.str.split str="$function_name" delimiter=.
        local segments=("${(@)REPLY}")
        z.int.is.lt ${#segments[@]} 3 && continue
        candidate="z.${segments[2]}."
        z.arr.includes target="$candidate" "${candidates[@]}" && continue
      fi
      candidates+=("$candidate")
    fi
  done

  if z.int.is.zero ${#candidates[@]}; then
    return 1
  fi

  z.arr.join.line "${candidates[@]}"
}
