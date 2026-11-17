# 補完カーソルより前のコード文字列を取得する
#
# $value: 引数全体の値
# $prefix: 名前付き引数の接頭辞
# $input_prefix: ZLEのカーソルより前の文字列
# $input_suffix: ZLEのカーソルより後ろの文字列
# REPLY: カーソルより前のコード
# return: 0
#
# example:
#  z.completion.code.context._prefix value=greet prefix=code= input_prefix=code=gr input_suffix=eet
#  # REPLY: "gr"
z.completion.code.context._prefix() {
  z.arg.named value "$@" && local value=$REPLY
  z.arg.named prefix "$@" && local prefix=$REPLY
  z.arg.named input_prefix "$@" && local input_prefix=$REPLY
  z.arg.named input_suffix "$@" && local input_suffix=$REPLY

  if z.is.null "$input_suffix"; then
    REPLY=$value
    return 0
  fi

  z.str.remove.prefix "$input_prefix" "$prefix"
  local candidate=$REPLY
  if z.str.start_with "$value" "$candidate"; then
    REPLY=$candidate
  else
    z.str.unquote "$candidate"
  fi
}

# Zshの字句分割から、現在のコマンドの単語を取得する
#
# $1: カーソルより前のコード
# REPLY: 現在のコマンドの単語。区切り直後は空の単語
# return: コード内なら0、コメント内なら1
#
# example:
#  z.completion.code.context._words "print ok; greet value"
#  # REPLY: ("greet" "value")
#  z.completion.code.context._words "true;"
#  # REPLY: ("")
z.completion.code.context._words() {
  local code_prefix=$1
  z.str.split.shell "$code_prefix" comments=keep newlines=whitespace
  local tokens=("${REPLY[@]}")
  z.str.start_with "$tokens[-1]" '#' && return 1
  local command_words=()
  local token

  for token in "${tokens[@]}"; do
    case $token in
      ';'|'&&'|'||'|'|'|'|&'|'&'|$'\n'|'(')
        command_words=()
        ;;
      if|then|else|elif|while|until|do|coproc|time)
        z.int.is.zero "${#command_words[@]}" || command_words+=("$token")
        ;;
      *)
        command_words+=("$token")
        ;;
    esac
  done

  local trailing_space='[[:space:]]$'
  if z.str.is.match "$code_prefix" "$trailing_space" || z.int.is.zero "${#command_words[@]}"; then
    command_words+=("")
  fi
  REPLY=("${command_words[@]}")
}

# 二重引用で囲まれた置換のカーソル前後を、入力済みの接頭辞から復元する
#
# $word: Zshが返した引用付きの単語
# $prefix: コードの字句分割で得たカーソル前の単語
# REPLY: 引用を除いた接頭辞、内側の引用符を除いた接尾辞
# return: 二重引用の単語なら0、それ以外は1
#
# example:
#  z.completion.code.context._substitution_cursor 'word="$(greet)"' 'prefix="$(gr'
#  # REPLY: ("$(gr" "eet)")
z.completion.code.context._substitution_cursor() {
  z.arg.named word "$@" && local word=$REPLY
  z.arg.named prefix "$@" && local prefix=$REPLY
  z.str.start_with "$prefix" '"$(' || return 1
  z.str.end_with "$prefix" '"' && return 1
  z.str.start_with "$word" '"$(' || return 1
  z.str.end_with "$word" '"' || return 1

  z.str.remove.prefix "$prefix" '"'
  local before=$REPLY
  local after=${word[$((${#prefix} + 1)),-1]}
  z.str.remove.suffix "$after" '"'
  REPLY=("$before" "$REPLY")
}
