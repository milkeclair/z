# 一致する接頭辞を除いた残りの文字列を取得する
#
# $1: 文字列
# $2: 先頭で照合する正規表現
# REPLY: 接頭辞に一致した後の残りの文字列。一致しなければ空
# return: null
#
# example:
#  z.str.match.rest "hello_world" "hello_"
#  # REPLY: "world"
#  z.str.match.rest "foo-bar-baz" "foo-"
#  # REPLY: "bar-baz"
z.str.match.rest() {
  local str=$1
  local regex=$2

  if z.str.is.match "$str" "^(${regex})"; then
    REPLY=${str[MEND + 1,-1]}
  else
    REPLY=""
  fi
}

# 正規表現に一致する文字列のn番目の要素を取得する
#
# $1: 文字列（空白区切りの要素）
# $2: 正規表現
# $index: 返す一致要素のインデックス（1始まり）
# REPLY: n番目の一致要素。見つからなければ空
# return: null
#
# example:
#  z.str.match.nth "one two three" "^o" index=1
#  # REPLY: "one"
#  z.str.match.nth "apple apricot cherry" "^a" index=2
#  # REPLY: "apricot"
z.str.match.nth() {
  z.arg.named index $@ && local index=$REPLY
  z.arg.named.shift index $@
  local str=$REPLY[1]
  local regex=$REPLY[2]

  local words=( ${=str} )
  local count=0

  for word in $words; do
    if z.str.is.match "$word" "$regex"; then
      ((count++))
      if z.int.is.eq $count $index; then
        REPLY=$word
        return
      fi
    fi
  done

  REPLY=""
}
