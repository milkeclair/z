# 文字列から指定した文字列の接頭辞を取り除く
#
# $1: 元の文字列
# $2: 接頭辞
# REPLY: 接頭辞を除いた文字列。接頭辞がなければ元の文字列
# return: null
#
# example:
#  z.str.remove.prefix "pr/123" "pr/" #=> "123"
#  z.str.remove.prefix "main" "pr/"   #=> "main"
z.str.remove.prefix() {
  local str=$1
  local prefix=$2

  if z.str.start_with "$str" "$prefix"; then
    REPLY="${str[${#prefix} + 1,-1]}"
  else
    REPLY="$str"
  fi
}

# 文字列から指定した文字列の接尾辞を取り除く
#
# $1: 元の文字列
# $2: 接尾辞
# REPLY: 接尾辞を除いた文字列。接尾辞がなければ元の文字列
# return: null
#
# example:
#  z.str.remove.suffix "file.zsh" ".zsh" #=> "file"
#  z.str.remove.suffix "README" ".md"    #=> "README"
z.str.remove.suffix() {
  local str=$1
  local suffix=$2

  if z.str.end_with "$str" "$suffix"; then
    REPLY="${str[1,${#str} - ${#suffix}]}"
  else
    REPLY="$str"
  fi
}
