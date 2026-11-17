# 引数仕様を名前付き・位置・残りの引数で検索できる形へ変換する
#
# $1: 改行で区切った仕様
# REPLY: 検索キーと仕様の組、lastは最後の位置指定
# return: 0
#
# example:
#  z.completion.argument.spec._index "positional 1 code"
#  # REPLYの要素: ("positional.1" "positional 1 code" "last" "1")
z.completion.argument.spec._index() {
  local -A indexed=([last]=0)
  local row
  for row in "${(@f)1}"; do
    z.completion.argument.record._decode "$row"
    local fields=("${REPLY[@]}")

    case $fields[1] in
      named|positional)
        indexed[$fields[1].$fields[2]]=$row
        if z.is.eq "$fields[1]" positional && z.int.is.gt "$fields[2]" "$indexed[last]"; then
          indexed[last]=$fields[2]
        fi
        ;;
      rest)
        indexed[rest]=$row
        ;;
    esac
  done

  z.hash.entries indexed
}

# 1つの単語へ対応する仕様を選び、位置引数の数を進める
#
# $specs: 検索用の連想配列名
# $position: 直前までに数えた位置引数
# $value: 現在の単語の値
# REPLY: 選んだ仕様、名前付き接頭辞、更新後の位置
# return: 0
#
# example:
#  local -A example_specs=([named.code]="named code code" [last]=0)
#  z.completion.argument.spec._match specs=example_specs position=0 value=code=print
#  # REPLY: ("named code code" "code=" "0")
z.completion.argument.spec._match() {
  z.arg.named specs "$@" && local specs_name=$REPLY
  z.arg.named position "$@" && local position=$REPLY
  z.arg.named value "$@" && local value=$REPLY
  z.hash.entries "$specs_name"
  local -A parameters=("${REPLY[@]}")
  local name_pattern='^[^=]+='
  z.str.match "$value" "$name_pattern"
  z.str.remove.suffix "$REPLY" "="
  local key=$REPLY
  local named_record=$parameters[named.$key]

  if z.is.not.null "$named_record" && z.str.start_with "$value" "$key="; then
    REPLY=("$named_record" "$key=" "$position")
    return 0
  fi

  ((position++))
  if z.int.is.gt "$position" "$parameters[last]"; then
    local selected=$parameters[rest]
  else
    local selected=$parameters[positional.$position]
  fi

  REPLY=("$selected" "" "$position")
}
