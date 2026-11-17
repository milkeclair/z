# 引用したコード引数をZshの補完単語へ分割して処理する
#
# $code: カーソルより前のコード
# REPLY: null
# return: 標準補完の結果
#
# example:
#  # ZLEでコード文字列内を補完中の場合
#  z.completion.code.command._complete 'code=print $(z.arg.g'
#  # 補完候補の例: z.arg.get
z.completion.code.command._complete() {
  z.arg.named code "$@" && local code=$REPLY

  compset -q
  z.completion.code.command._run "code=$code" depth=0
}

# 現在のコマンドへ補完対象を合わせ、置換内では同じ引用段数で処理する
#
# $code: 現在の文脈のコード
# $depth: コマンド置換の深さ
# REPLY: null
# return: 標準補完の結果。上限に達した場合は0
#
# example:
#  # ZLEで引用を外したコードの補完中の場合
#  z.completion.code.command._run code=z.arg.g depth=0
#  # 補完候補の例: z.arg.get
z.completion.code.command._run() {
  z.arg.named code "$@" && local code=$REPLY
  z.arg.named depth "$@" && local depth=$REPLY
  local z_completion_command_depth=$depth
  if z.int.is.gteq "$depth" 32 || z.int.is.gt "${z_completion_code_depth:-0}" 32; then
    _message -r "code argument nesting limit"
    return 0
  fi

  z.completion.code.context._words "$code" || return 1
  local current_command=("${REPLY[@]}")
  local word_prefix=$current_command[-1]
  local ignored_length=$((${#PREFIX} - ${#word_prefix}))
  z.int.is.positive "$ignored_length" && compset -p "$ignored_length"
  local native_word=$words[$CURRENT]
  if z.completion.code.context._substitution_cursor "word=$native_word" "prefix=$word_prefix"; then
    PREFIX=$REPLY[1]
    SUFFIX=$REPLY[2]
  fi
  local suffix_words=("${words[@]:$CURRENT}")
  words=("${current_command[@]}" "${suffix_words[@]}")
  CURRENT=${#current_command[@]}
  words[$CURRENT]=$native_word

  z.completion.code.command._dispatch "prefix=$word_prefix" "depth=$depth"
}

# 置換の内側へ進むか、現在の文脈を標準補完へ渡す
#
# $prefix: 字句分割で得たカーソル前の単語
# $depth: コマンド置換の深さ
# REPLY: null
# return: 標準補完の結果
#
# example:
#  # ZLEで「$(z.arg.g」の内側を補完中の場合
#  z.completion.code.command._dispatch 'prefix=$(z.arg.g' depth=0
#  # 補完候補の例: z.arg.get
z.completion.code.command._dispatch() {
  z.arg.named prefix "$@" && local word_prefix=$REPLY
  z.arg.named depth "$@" && local depth=$REPLY

  if z.str.start_with "$PREFIX" '$(' && ! z.str.start_with "$word_prefix" "'"; then
    compset -p 2
    if z.str.end_with "$SUFFIX" ')"'; then
      compset -s 2
    elif z.str.end_with "$SUFFIX" ')'; then
      compset -s 1
    fi
    local z_completion_code_depth=$((${z_completion_code_depth:-0} + 1))
    z.completion.code.command._run "code=$PREFIX" "depth=$((depth + 1))"
  else
    z.int.is.positive "$depth" && words[$CURRENT]="$PREFIX$SUFFIX"
    _normal
  fi
}
