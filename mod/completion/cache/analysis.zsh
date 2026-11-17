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

  z.hash.keys z_completion_docs
  z.arr.sort "${REPLY[@]}"
  local doc_names=("${REPLY[@]}")
  local key function_name
  for key in "${doc_names[@]}"; do
    local value=${z_completion_docs[$key]}
    z.arr.quote style=double "$key" "$value"
    lines+=("z_completion_docs+=($REPLY[1] $REPLY[2])")
  done

  z.hash.keys z_completion_argument_specs
  z.arr.sort "${REPLY[@]}"
  local spec_names=("${REPLY[@]}")
  for function_name in "${spec_names[@]}"; do
    local specs=${z_completion_argument_specs[$function_name]}
    z.arr.quote style=double "$function_name" "$specs"
    lines+=("z_completion_argument_specs+=($REPLY[1] $REPLY[2])")
  done

  z.arr.quote style=double "${z_completion_function_names[@]}"
  for function_name in "${REPLY[@]}"; do
    lines+=("z_completion_function_names+=($function_name)")
  done

  lines+=("z_completion_cache_ready=true")
  z.arr.join.line "${lines[@]}"
}
