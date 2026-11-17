# 関数コメントの引数宣言を読み、種類・名前・型・コロン位置・許可値を返す
#
# $1: 引数コメントの本文
# REPLY: 引数種別、名前、型、コロンの位置（1始まり）、許可値の配列
# return: 宣言が正しい場合は0、それ以外は1
#
# example:
#  z.completion.argument._parse '$code [code]: commands'
#  # REPLY: ("named" "code" "code" "13")
z.completion.argument._parse() {
  z.str.trim "$1"
  local line=$REPLY
  REPLY=""

  [[ $line[1] == '$' ]] || return 1
  local cursor=2
  local kind=named

  case $line[$cursor] in
    [0-9])
      kind=positional
      while [[ $line[$cursor] == [0-9] ]]; do ((cursor++)); done
      ;;
    [A-Za-z_])
      while [[ $line[$cursor] == [A-Za-z0-9_] ]]; do ((cursor++)); done
      ;;
    '@'|'*')
      kind=rest
      ((cursor++))
      ;;
    *)
      return 1
      ;;
  esac

  local marker=${line[2,$((cursor - 1))]}
  [[ $kind == positional && $marker == 0 ]] && return 1
  [[ $line[$cursor] == '?' ]] && ((cursor++))
  while [[ $line[$cursor] == [[:space:]] ]]; do ((cursor++)); done

  local value_type=plain
  local literals=()
  if [[ $line[$cursor] == '[' ]]; then
    [[ ${line[$cursor,$((cursor + 4))]} == '[code' ]] || return 1
    value_type=code
    ((cursor += 5))

    while ((cursor <= ${#line})); do
      while [[ $line[$cursor] == [[:space:]] ]]; do ((cursor++)); done
      if [[ $line[$cursor] == ']' ]]; then
        ((cursor++))
        break
      fi

      [[ $line[$cursor] == '|' ]] || return 1
      ((cursor++))
      while [[ $line[$cursor] == [[:space:]] ]]; do ((cursor++)); done
      local quote=$line[$cursor]
      [[ $quote == "'" || $quote == '"' ]] || return 1
      ((cursor++))

      local literal=""
      local closed=false
      while ((cursor <= ${#line})); do
        local char=$line[$cursor]
        if [[ $char == $quote ]]; then
          closed=true
          ((cursor++))
          break
        fi
        local next=$line[$((cursor + 1))]
        if [[ $char == '\' && ( $next == $quote || $next == '\' ) ]]; then
          char=$next
          ((cursor++))
        fi
        literal+=$char
        ((cursor++))
      done

      z.is.true "$closed" || return 1
      literals+=("$literal")
    done
    while [[ $line[$cursor] == [[:space:]] ]]; do ((cursor++)); done
  fi

  [[ $line[$cursor] == ':' ]] || return 1
  REPLY=("$kind" "$marker" "$value_type" "$cursor" "${literals[@]}")
}

# code引数のある関数について、引数仕様を評価不要のキャッシュ文字列へ変換する
#
# $1: コメント記号を外した関数ドキュメント
# REPLY: 引数ごとの種類・名前・型・許可値を引用した行、または空文字
# return: 0
#
# example:
#  z.completion.argument._docs '$code [code]: commands'
#  # REPLY: "named code code"
z.completion.argument._docs() {
  local records=()
  local has_code=false
  local line
  for line in "${(@f)1}"; do
    z.str.trim "$line"
    local trimmed=$REPLY
    [[ $trimmed == example:* ]] && break
    [[ $trimmed == '$'* ]] || continue
    z.completion.argument._parse "$trimmed" || continue
    local fields=("${REPLY[@]}")
    [[ $fields[3] == code ]] && has_code=true
    fields[4]=()
    records+=("${(j: :)${(@q)fields}}")
  done

  if z.is.true "$has_code"; then
    REPLY="${(F)records}"
  else
    REPLY=""
  fi
}

# キャッシュ済み仕様と補完単語から、現在のコード引数を選ぶ
#
# $1: キャッシュした引数仕様
# $2: 現在の単語位置
# $@: コマンド名を含む単語
# REPLY: 名前付き接頭辞と許可値の配列
# return: code引数の位置なら0、それ以外は1
#
# example:
#  z.completion.argument._select "named code code call_original" 2 run_code code=print
#  # REPLY: ("code=" "call_original")
z.completion.argument._select() {
  local records=$1
  local current=$2
  shift 2
  local args=("$@")
  local -A named=() positional=()
  local rest=""
  local last=0
  local row

  REPLY=""
  ((current >= 2)) || return 1
  for row in "${(@f)records}"; do
    local fields=("${(@Q)${(z)row}}")
    case $fields[1] in
      named) named[$fields[2]]=$row ;;
      positional)
        positional[$fields[2]]=$row
        ((fields[2] > last)) && last=$fields[2]
        ;;
      rest) rest=$row ;;
    esac
  done

  local position=0
  local idx
  for ((idx=2; idx<=current; idx++)); do
    local value=$args[$idx]
    local key=${value%%=*}
    if [[ $value == *=* && -n $named[$key] ]]; then
      local selected=$named[$key]
      local prefix="$key="
    else
      ((position++))
      local prefix=""
      if ((position > last)); then
        local selected=$rest
      else
        local selected=$positional[$position]
      fi
    fi

    if ((idx == current)); then
      local fields=("${(@Q)${(z)selected}}")
      [[ $fields[3] == code ]] || return 1
      REPLY=("$prefix" "${fields[@]:3}")
      return 0
    fi
  done

  return 1
}

# Zshの引用解除を使い、入力途中で閉じていない引用符も復号する
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
  local value=${(Q)input}
  if [[ $value != "$input" || ( $input != *\'* && $input != *\"* ) ]]; then
    REPLY=$value
    return 0
  fi

  local quote
  for quote in "'" '"'; do
    local closed="$input$quote"
    local decoded=${(Q)closed}
    if [[ $decoded != "$closed" ]]; then
      REPLY=$decoded
      return 0
    fi
  done

  REPLY=""
  return 1
}
