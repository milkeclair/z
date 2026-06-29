# register z completion definitions for current candidates
#
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.compdef._register
z.completion.compdef._register() {
  if z.int.is.zero ${+functions[compdef]}; then
    return 1
  fi

  _z_completion() {
    z.completion.complete._run "$@"
  }

  for function_name in "${z_completion_function_names[@]}"; do
    compdef _z_completion $function_name
  done
}

# hide private z functions from command position completion
#
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.compdef._ignore_private
z.completion.compdef._ignore_private() {
  local context=':completion:*:*:-command-:*:functions'
  local private_pattern='z.*._*'
  local -a ignored_patterns=()

  zstyle -a $context ignored-patterns ignored_patterns
  if z.arr.includes target=$private_pattern "${ignored_patterns[@]}"; then
    return 0
  fi

  ignored_patterns+=("$private_pattern")
  zstyle $context ignored-patterns "${ignored_patterns[@]}"
}
