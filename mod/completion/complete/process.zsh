# complete z functions or show docs for the current completion context
#
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.complete._run
z.completion.complete._run() {
  if z.completion.complete._functions; then
    return
  fi

  z.completion.complete._docs
}

# complete z function names for the current word
#
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.complete._functions
z.completion.complete._functions() {
  local current_word=${words[$CURRENT]:-}
  if ! z.str.start_with "$current_word" "z."; then
    return 1
  fi

  z.completion.function._candidates "$current_word" || return 1
  local candidates=("${(@f)REPLY}")
  _describe -t z-functions "z functions" candidates
}

# show docs for the function near the current completion word
#
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.complete._docs
z.completion.complete._docs() {
  z.completion.function.name._words || return 1
  local function_name=$REPLY

  z.completion.docs._get $function_name || return 1
  if z.int.is.positive ${+compstate}; then
    compstate[list]="list force messages"
  fi
  _message -r "$REPLY"
}
