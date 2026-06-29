# dump completion cache as sourceable zsh
#
# REPLY: sourceable zsh cache
# return: null
#
# example:
#  z.completion.cache._dump
z.completion.cache._dump() {
  local lines=(
    "typeset -gA z_completion_docs=()"
    "typeset -ga z_completion_function_names=()"
    "typeset -g z_completion_cache_ready=false"
  )

  for key in ${(ko)z_completion_docs}; do
    local value=${z_completion_docs[$key]}
    lines+=("z_completion_docs[${(qqq)key}]=${(qqq)value}")
  done

  for function_name in ${z_completion_function_names[@]}; do
    lines+=("z_completion_function_names+=(${(qqq)function_name})")
  done

  lines+=("z_completion_cache_ready=true")
  z.arr.join.line "${lines[@]}"
}
