# 現在の候補に対するzの補完定義を登録する
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

  if z.is.not.eq "${_comps[-command-]}" z.completion.complete._command; then
    z_completion_command_function=${_comps[-command-]}
    compdef z.completion.complete._command -command- || return 1
  fi

  for function_name in "${z_completion_function_names[@]}"; do
    compdef _z_completion $function_name
  done
}

# コマンド位置の補完から非公開のz関数を隠す
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
