# sourceできるZshコードとして補完キャッシュを出力する
#
# REPLY: sourceできるZshのキャッシュ
# return: null
#
# example:
#  local -A z_completion_docs=()
#  local -a z_completion_function_names=()
#  z.completion.cache._dump
#  # REPLY:
#  # typeset -gA z_completion_docs=()
#  # typeset -gA z_completion_argument_specs=()
#  # typeset -ga z_completion_function_names=()
#  # typeset -g z_completion_cache_ready=false
#  # z_completion_cache_ready=true
z.completion.cache._dump() {
  local lines=(
    "typeset -gA z_completion_docs=()"
    "typeset -gA z_completion_argument_specs=()"
    "typeset -ga z_completion_function_names=()"
    "typeset -g z_completion_cache_ready=false"
  )

  local key function_name
  for key in ${(ko)z_completion_docs}; do
    local value=${z_completion_docs[$key]}
    lines+=("z_completion_docs+=(${(qqq)key} ${(qqq)value})")
  done

  z.hash.keys z_completion_argument_specs
  z.arr.sort "${REPLY[@]}"
  local spec_names=("${REPLY[@]}")
  for function_name in "${spec_names[@]}"; do
    local specs=${z_completion_argument_specs[$function_name]}
    lines+=("z_completion_argument_specs+=(${(qqq)function_name} ${(qqq)specs})")
  done

  for function_name in ${z_completion_function_names[@]}; do
    lines+=("z_completion_function_names+=(${(qqq)function_name})")
  done

  lines+=("z_completion_cache_ready=true")
  z.arr.join.line "${lines[@]}"
}
