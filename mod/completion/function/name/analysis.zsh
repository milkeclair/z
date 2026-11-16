# 宣言行からzの関数名を取り出す
#
# $1: ソース行
# REPLY: 関数名|null
# return: 0|1
#
# example:
#  z.completion.function.name._declaration "z.example() {"
z.completion.function.name._declaration() {
  local line=$1

  z.str.gsub str="$line" search="^[[:space:]]+" replace=""
  local trimmed_line=$REPLY
  if ! z.str.is.match "$trimmed_line" '^z[.].*\(\)'; then
    return 1
  fi

  z.str.partition "$trimmed_line" "()" literal=true
  local -a declaration=("${(@)REPLY}")
  local function_name=$declaration[1]
  local declaration_suffix=$declaration[2]

  z.str.gsub str="$declaration_suffix" search="^[[:space:]]+" replace=""
  declaration_suffix=$REPLY
  if ! z.is.eq "$declaration_suffix" "{"; then
    return 1
  fi

  REPLY="$function_name"
}

# 補完対象の単語からzの関数名を見つける
#
# REPLY: 関数名|null
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
      REPLY="$word"
      return
    fi
  done

  return 1
}
