# 関数コメントから引数の種類・名前・型・コロン位置・許可値を返す
#
# $1: 引数コメントの本文
# REPLY: 種類、名前、型、コロン位置（1始まり）、許可値
# return: 引数の宣言なら0、それ以外は1
#
# example:
#  z.completion.argument._parse '$code [code]: commands'
#  # REPLY: ("named" "code" "code" "13")
z.completion.argument._parse() {
  z.str.trim "$1"
  local line=$REPLY
  z.completion.argument.parameter._read "$line" || return 1
  local parameter=("${REPLY[@]}")
  local remaining=$parameter[3]
  local value_type=plain
  local literals=()

  if z.str.start_with "$remaining" '['; then
    z.completion.argument.type._read "$remaining" || return 1
    remaining=$REPLY[1]
    literals=("${REPLY[@]:1}")
    value_type=code
  fi

  z.str.trim "$remaining"
  remaining=$REPLY
  z.str.start_with "$remaining" ':' || return 1
  local column=$((${#line} - ${#remaining} + 1))
  REPLY=("$parameter[1]" "$parameter[2]" "$value_type" "$column" "${literals[@]}")
}

# code引数のある関数について引数仕様をキャッシュ用の行へまとめる
#
# $1: コメント記号を外した関数ドキュメント
# REPLY: 引用した仕様を改行で区切った文字列、または空文字
# return: 0
#
# example:
#  z.completion.argument._docs '$code [code]: commands'
#  # REPLY: "$'named' $'code' $'code'"
z.completion.argument._docs() {
  if ! z.str.includes "$1" '[code'; then
    REPLY=""
    return 0
  fi

  local records=()
  local has_code=false
  local line
  z.str.split.line "$1"
  for line in "${REPLY[@]}"; do
    z.str.trim "$line"
    local trimmed=$REPLY
    z.str.start_with "$trimmed" example: && break
    z.str.start_with "$trimmed" '$' || continue
    z.completion.argument._parse "$trimmed" || continue
    local fields=("${REPLY[@]}")
    z.is.eq "$fields[3]" code && has_code=true

    fields[4]=()
    z.completion.argument.record._encode "${fields[@]}"
    records+=("$REPLY")
  done

  if z.is.true "$has_code"; then
    z.arr.join.line "${records[@]}"
  else
    REPLY=""
  fi
}

# 現在の補完単語に対応するコード引数を選ぶ
#
# $specs: キャッシュした引数仕様
# $current: 現在の単語位置
# $words: コマンド名を含む単語の配列名
# REPLY: 名前付き接頭辞、許可値
# return: code引数の位置なら0、それ以外は1
#
# example:
#  local example_words=(run_code code=print)
#  z.completion.argument._select specs="named code code noop" current=2 words=example_words
#  # REPLY: ("code=" "noop")
z.completion.argument._select() {
  z.arg.named specs "$@" && local specs=$REPLY
  z.arg.named current "$@" && local current=$REPLY
  z.arg.named words "$@" && local words_name=$REPLY
  z.int.is.gteq "$current" 2 || return 1
  z.completion.argument.spec._index "$specs"
  local -A indexed_specs=("${REPLY[@]}")
  z.var.get "$words_name"
  local args=("${REPLY[@]}")
  local selection=()
  local position=0
  local idx

  for ((idx=2; idx<=current; idx++)); do
    z.completion.argument.spec._match specs=indexed_specs "position=$position" "value=$args[$idx]"
    selection=("${REPLY[@]}")
    position=$selection[3]
  done

  z.completion.argument.record._decode "$selection[1]"
  local fields=("${REPLY[@]}")
  REPLY=""
  z.is.eq "$fields[3]" code || return 1
  REPLY=("$selection[2]" "${fields[@]:3}")
}

# Zshの引用解除を使い、閉じていない引用符も復号する
#
# $1: シェル上の単語
# REPLY: 引用を外した値
# return: 復号できた場合は0、それ以外は1
#
# example:
#  z.completion.argument._value "code='z.arg.g"
#  # REPLY: "code=z.arg.g"
z.completion.argument._value() {
  local input=$1
  z.str.unquote "$input"
  local value=$REPLY
  local quote_pattern="[\\\"']"
  if z.is.not.eq "$value" "$input" || ! z.str.is.match "$input" "$quote_pattern"; then
    REPLY=$value
    return 0
  fi

  local quote
  for quote in "'" '"'; do
    local closed="$input$quote"
    z.str.unquote "$closed"
    local decoded=$REPLY
    if z.is.not.eq "$decoded" "$closed"; then
      REPLY=$decoded
      return 0
    fi
  done

  REPLY=""
  return 1
}
