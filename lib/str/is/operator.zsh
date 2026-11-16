# 文字列が空か確認する
#
# $1: 文字列
# REPLY: null
# 0|1を返す
#
# example:
#  z.str.is.empty ""
#  z.str.is.empty "hello"
z.str.is.empty() {
  local value=$1

  [[ -z $value ]]
}

# 文字列が正規表現に一致するか確認する
#
# $1: 文字列
# $2: 正規表現
# REPLY: null
# 0|1を返す
#
# example:
#  z.str.is.match "hello" "^h.*o$"  #=> 0 (true)
#  z.str.is.match "hello" "^H.*O$"  #=> 1 (false, case-sensitive)
z.str.is.match() {
  local string=$1
  local regex=$2

  [[ $string =~ $regex ]]
}

# 文字列がパスの形式か確認する
#
# $1: 文字列
# REPLY: null
# 0|1を返す
#
# example:
#  z.str.is.path_like "/usr/local/bin"  #=> 0 (true)
#  z.str.is.path_like "~/documents"     #=> 0 (true)
#  z.str.is.path_like "./script.sh"     #=> 0 (true)
#  z.str.is.path_like "../config"       #=> 0 (true)
#  z.str.is.path_like "."               #=> 0 (true)
#  z.str.is.path_like ".."              #=> 0 (true)
#  z.str.is.path_like "not/a/path"      #=> 1 (false)
z.str.is.path_like() {
  local value=$1

  z.str.is.match "$value" "^/" && return 0
  z.str.is.match "$value" "^~" && return 0
  z.str.is.match "$value" "^\./" && return 0
  z.str.is.match "$value" "^\.\./" && return 0
  z.is.eq "$value" "." && return 0
  z.is.eq "$value" ".." && return 0

  return 1
}
