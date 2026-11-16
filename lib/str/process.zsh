typeset -gA z_color_palette=(
  [red]=$'\033[31m'
  [green]=$'\033[32m'
  [orange]=$'\033[38;5;208m'
  [yellow]=$'\033[33m'
  [blue]=$'\033[34m'
  [magenta]=$'\033[35m'
  [cyan]=$'\033[36m'
  [white]=$'\033[37m'
  [reset]=$'\033[0m'
)

# 名前からカラーコードを取得する
#
# $1: 色名
# REPLY: カラーコード
# return: null
#
# example:
#  z.str.color red #=> "\033[31m"
z.str.color() {
  local selected=$1

  REPLY=${z_color_palette[$selected]}
}

# 指定した段階で文字列をインデントする
#
# $level: インデントの段階（空白2個を1段階とする）
# $message: インデントする文字列
# REPLY: インデントした文字列
# return: null
#
# example:
#  z.str.indent level=2 message="Hello" #=> "    Hello"
z.str.indent() {
  z.arg.named level $@ && local level=$REPLY
  z.arg.named message $@ && local message=$REPLY

  if z.int.is.not.match $level || z.int.is.lt $level 0; then
    level=0
  fi

  local indent=""
  for ((i=0; i<level; i++)); do
    indent+="  "
  done

  REPLY="${indent}${message}"
}

# 文字列を区切りで分割する
#
# $str: 分割する文字列
# $delimiter?: 区切り文字（既定: "|"）
# REPLY: 分割した文字列の配列
# return: null
#
# example:
#  z.str.split str="apple|banana|cherry" delimiter=| #=> ("apple" "banana" "cherry")
z.str.split() {
  z.arg.named str $@ && local str=$REPLY
  z.arg.named delimiter $@ default="|" && local delimiter=$REPLY

  local IFS=$delimiter
  REPLY=(${=str})
}

# 区切りに最初に一致する位置で文字列を2つに分割する
#
# $1: 元の文字列
# $2: 区切り文字の正規表現または文字列
# $literal?: trueなら区切りを通常の文字列として扱う（既定: false）
# REPLY: 左側と右側の文字列の配列
# return: null
#
# example:
#  z.str.partition "p foo bar" "[[:space:]]+" #=> ("p" "foo bar")
#  z.str.partition "a[0-9]b" "[0-9]" literal=true #=> ("a" "b")
z.str.partition() {
  z.arg.named literal $@ default=false && local literal=$REPLY
  z.arg.named.shift literal $@
  local str=$REPLY[1]
  local delimiter=$REPLY[2]

  if z.is.null "$delimiter"; then
    REPLY=("$str" "")
    return
  fi

  if z.is.true $literal; then
    local delimiter_length=${#delimiter}
    local last_delimiter_start=$((${#str} - delimiter_length + 1))

    local delimiter_start
    for (( delimiter_start=1; delimiter_start<=last_delimiter_start; delimiter_start++ )); do
      local candidate_end=$((delimiter_start + delimiter_length - 1))
      local candidate=${str[delimiter_start,candidate_end]}

      if z.is.eq "$candidate" "$delimiter"; then
        local left=${str[1,delimiter_start - 1]}
        local right=${str[candidate_end + 1,-1]}
        REPLY=("$left" "$right")
        return
      fi
    done

    REPLY=("$str" "")
    return
  fi

  if [[ $str =~ $delimiter ]]; then
    local match_start=$MBEGIN
    local match_end=$MEND
    local right_start=$((match_end + 1))

    if z.int.is.lt $match_end $match_start; then
      right_start=$match_start
    fi

    REPLY=("${str[1,match_start - 1]}" "${str[right_start,-1]}")
  else
    REPLY=("$str" "")
  fi
}

# 文字列を正規表現と照合する
#
# $1: 文字列
# $2: 正規表現
# REPLY: 一致した文字列
# return: null
#
# example:
#  z.str.match "helloWorld" "[a-z]+" #=> "hello"
z.str.match() {
  local str=$1
  local regex=$2

  [[ $str =~ $regex ]] && REPLY="$MATCH" || REPLY=""
}

# 文字列全体を置換する
#
# $str: 元の文字列
# $search: 検索する正規表現または文字列
# $replace: 置換後の文字列
# $literal?: trueなら検索対象を通常の文字列として扱う（既定: false）
# REPLY: 変更後の文字列
# return: null
#
# example:
#  z.str.gsub str="Hello World" search="World" replace="Zsh" #=> "Hello Zsh"
#  z.str.gsub str="Hello123World" search="[0-9]" replace="-" #=> "Hello---World"
#  z.str.gsub str="a[0-9]b" search="[0-9]" replace="X" literal=true #=> "aXb"
z.str.gsub() {
  z.arg.named str $@ && local str=$REPLY
  z.arg.named search $@ && local search=$REPLY
  z.arg.named replace $@ && local replace=$REPLY
  z.arg.named literal $@ default=false && local literal=$REPLY

  if z.is.null $str || z.is.null $search; then
    REPLY=$str
  elif z.is.true $literal; then
    REPLY=${str//$search/$replace}
  else
    local result=""
    local rest=$str

    while [[ $rest =~ $search ]]; do
      local match=$MATCH
      local match_start=$MBEGIN
      local match_end=$MEND

      if z.str.is.empty "$match"; then
        result+="${rest[1,match_start - 1]}"
        MATCH=$match
        result+="${(e)replace}"
        result+="${rest[match_start,-1]}"
        REPLY="$result"
        return
      fi

      result+="${rest[1,match_start - 1]}"
      MATCH=$match
      result+="${(e)replace}"
      rest=${rest[match_end + 1,-1]}
    done

    REPLY="${result}${rest}"
  fi
}

# 文字列を大文字に変換する
#
# $1: 元の文字列
# REPLY: 大文字の文字列
# return: null
#
# example:
#  z.str.upcase "hello" #=> "HELLO"
z.str.upcase() {
  local str=$1

  REPLY=${(U)str}
}

# 文字列を小文字に変換する
#
# $1: 元の文字列
# REPLY: 小文字の文字列
# return: null
#
# example:
#  z.str.downcase "HELLO" #=> "hello"
z.str.downcase() {
  local str=$1

  REPLY=${(L)str}
}

# 文字列をcamelCaseに変換する
#
# $1: 元の文字列
# REPLY: camelCase形式の文字列
# return: null
#
# example:
#  z.str.camelize "hello_world" #=> "helloWorld"
z.str.camelize() {
  local str=$1
  local result=""
  local capitalize_next=false

  z.group "downcase if delimiters exist"; {
    if z.str.is.match "$str" "[ _-]"; then
      z.str.downcase "$str"
      str=$REPLY
    fi
  }

  for (( i=1; i<=${#str}; i++ )); do
    local char=${str[i]}

    if z.str.is.match $char "[ _-]"; then
      capitalize_next=true
    elif $capitalize_next; then
      result+=${(U)char}
      capitalize_next=false
    else
      result+=$char
    fi
  done

  REPLY=${(L)result[1]}${result[2,-1]}
}

# 文字列をPascalCaseに変換する
#
# $1: 元の文字列
# REPLY: PascalCase形式の文字列
# return: null
#
# example:
#  z.str.pascalize "hello_world" #=> "HelloWorld"
z.str.pascalize() {
  local str=$1
  local result=""
  local capitalize_next=true

  z.group "downcase if delimiters exist"; {
    if z.str.is.match "$str" "[ _-]"; then
      z.str.downcase "$str"
      str=$REPLY
    fi
  }

  for (( i=1; i<=${#str}; i++ )); do
    local char=${str[i]}

    if z.str.is.match $char "[ _-]"; then
      capitalize_next=true
    elif $capitalize_next; then
      result+=${(U)char}
      capitalize_next=false
    else
      result+=$char
    fi
  done

  REPLY=$result
}

# 文字列をCONSTANTIZE形式に変換する
#
# $1: 元の文字列
# REPLY: CONSTANTIZE形式の文字列
# return: null
#
# example:
#  z.str.constantize "helloWorld" #=> "HELLO_WORLD"
z.str.constantize() {
  local str=$1
  local result=""
  local previous_char=""

  z.str.upcase $str
  str=$REPLY

  for (( i=1; i<=${#str}; i++ )); do
    local char=${str[i]}

    if z.str.is.match $char "[ _-]"; then
      if z.is.not.eq "$previous_char" "_"; then
        result+="_"
        previous_char="_"
      fi
    else
      previous_char=$char
      result+=$char
    fi
  done

  REPLY=$result
}

# 文字列をunderscore_caseに変換する
#
# $1: 元の文字列
# REPLY: underscore_case形式の文字列
# return: null
#
# example:
#  z.str.underscore "helloWorld" #=> "hello_world"
z.str.underscore() {
  local str=$1

  z.str.delimitize $str delimiter="_" replace_chars="[ -]"
}

# 文字列をkebab-caseに変換する
#
# $1: 元の文字列
# REPLY: kebab-case形式の文字列
# return: null
#
# example:
#  z.str.kebabize "helloWorld" #=> "hello-world"
z.str.kebabize() {
  local str=$1

  z.str.delimitize $str delimiter="-" replace_chars="[ _]"
}

# 区切り文字を挿入して文字列を変換する
#
# $delimiter: 挿入する区切り文字
# $replace_chars: 区切り文字へ置換する文字（既定: "[ _-]"）
# $1: 元の文字列
# REPLY: 変換した文字列
# return: null
#
# example:
#  z.str.delimitize delimiter="_" "helloWorld" #=> "hello_world"
#  z.str.delimitize delimiter="-" replace_chars="[ _]" "hello world_test" #=> "hello-world-test"
z.str.delimitize() {
  z.arg.named delimiter $@ && local delimiter=$REPLY
  z.arg.named replace_chars $@ default="[ _-]" && local replace_chars=$REPLY
  z.arg.named.shift delimiter $@
  z.arg.named.shift replace_chars $REPLY

  local str=$REPLY
  local result=""

  z.group "downcase if delimiters exist"; {
    if z.str.is.match "$str" "[ _-]"; then
      z.str.downcase "$str"
      str=$REPLY
    fi
  }

  # 大文字の前へ区切り文字を挿入する
  # 例: "helloWorld" -> "hello_World"（区切りが"_"の場合）
  z.str.gsub str="$str" search="[A-Z]" replace='${delimiter}${MATCH}'
  result=${(L)REPLY}

  # 指定した文字を区切り文字へ置換する
  # 例: "hello world-test" -> "hello_world_test"（区切りが"_"、replace_charsが"[ -]"の場合）
  z.str.gsub str="$result" search="$replace_chars" replace="${delimiter}"
  result=$REPLY

  # 連続する区切り文字をまとめる
  # 例: "hello__world" -> "hello_world"（区切りが"_"の場合）
  while z.str.includes "$result" "${delimiter}${delimiter}"; do
    z.str.gsub str="$result" search="${delimiter}${delimiter}" replace="${delimiter}" literal=true
    result=$REPLY
  done

  # 先頭の区切り文字を取り除く
  # 例: "_hello_world" -> "hello_world"（区切りが"_"の場合）
  z.str.remove.prefix "$result" "$delimiter"
  result=$REPLY

  REPLY=${(L)result}
}

# 文字列を可視化する（表示できない文字をエスケープする）
#
# $1: 元の文字列
# REPLY: 可視化した文字列
# return: null
#
# example:
#  z.str.visible $'\nHello\tWorld' #=> '\nHello\tWorld'
z.str.visible() {
  local str=$1

  REPLY=${(V)str}
}

# 指定した幅と埋める文字で文字列を左寄せする
#
# $width: 結果の文字列の幅
# $fill?: 埋める文字（既定: 空白）
# $1: 元の文字列
# REPLY: 左寄せした文字列
# return: null
#
# example:
#  z.str.ljust width=10 fill="." "Hi" #=> "Hi........"
z.str.ljust() {
  z.arg.named width $@ && local width=$REPLY
  z.arg.named fill $@ default=" " && local fill=$REPLY
  z.arg.named.shift width $@
  z.arg.named.shift fill $REPLY
  local str=$REPLY

  local str_length=${#str}
  if z.int.is.gteq $str_length $width; then
    REPLY=$str
    return
  fi

  local padding_length=$((width - str_length))
  local padding=""
  for (( i=0; i<padding_length; i++ )); do
    padding+=$fill
  done

  REPLY="${str}${padding}"
}

# 指定した幅と埋める文字で文字列を右寄せする
#
# $width: 結果の文字列の幅
# $fill?: 埋める文字（既定: 空白）
# $1: 元の文字列
# REPLY: 右寄せした文字列
# return: null
#
# example:
#  z.str.rjust width=10 fill="." "Hi" #=> "........Hi"
z.str.rjust() {
  z.arg.named width $@ && local width=$REPLY
  z.arg.named fill $@ default=" " && local fill=$REPLY
  z.arg.named.shift width $@
  z.arg.named.shift fill $REPLY
  local str=$REPLY

  local str_length=${#str}
  if z.int.is.gteq $str_length $width; then
    REPLY=$str
    return
  fi

  local padding_length=$((width - str_length))
  local padding=""
  for (( i=0; i<padding_length; i++ )); do
    padding+=$fill
  done

  REPLY="${padding}${str}"
}

# 文字列の前後の空白を取り除く
#
# $1: 元の文字列
# REPLY: 前後の空白を除いた文字列
# return: null
#
# example:
#  z.str.trim "  Hello World  " #=> "Hello World"
z.str.trim() {
  local str=$1

  setopt local_options EXTENDED_GLOB
  str=${str##[[:space:]]##}
  str=${str%%[[:space:]]##}

  REPLY="$str"

}
