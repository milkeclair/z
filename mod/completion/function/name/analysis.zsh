# extract a z function name from a declaration line
#
# $1: source line
# REPLY: function name|null
# return: 0|1
#
# example:
#  z.completion.function.name._declaration "z.example() {"
z.completion.function.name._declaration() {
  local line=$1

  z.help._trim_left_whitespace "$line"
  local trimmed_line=$REPLY
  if ! z.str.is.match "$trimmed_line" 'z.*\(\)*'; then
    return 1
  fi

  local function_name=${trimmed_line%%\(\)*}
  local declaration_suffix=${trimmed_line#"$function_name()"}
  z.help._trim_left_whitespace "$declaration_suffix"
  if ! z.is.eq "$REPLY" "{"; then
    return 1
  fi

  z.return "$function_name"
}

# find the z function name from completion words
#
# REPLY: function name|null
# return: 0|1
#
# example:
#  z.completion.function.name._words
z.completion.function.name._words() {
  local current=$CURRENT # 現在のカーソル位置
  if z.int.is.gt $current ${#words[@]}; then
    current=${#words[@]}
  fi

  local i=0
  for ((i=current; i>=1; i--)); do
    local word=${words[$i]}
    if z.str.start_with "$word" "z." && z.int.is.positive ${+functions[$word]}; then
      z.return "$word"
      return
    fi
  done

  return 1
}
