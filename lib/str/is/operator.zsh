# 文字列が空か確認する
#
# $1: 文字列
# REPLY: null
# return: 0|1
#
# example:
#  z.str.is.empty ""
#  # return: 0
#  z.str.is.empty "hello"
#  # return: 1
z.str.is.empty() {
  local value=$1

  [[ -z $value ]]
}

# 文字列が正規表現に一致するか確認する
#
# $1: 文字列
# $2: 正規表現
# REPLY: null
# return: 0|1
#
# example:
#  z.str.is.match "hello" "^h.*o$"
#  # return: 0
#  z.str.is.match "hello" "^H.*O$"
#  # return: 1
z.str.is.match() {
  local string=$1
  local regex=$2

  [[ $string =~ $regex ]]
}

# 文字列がパスの形式か確認する
#
# $1: 文字列
# REPLY: null
# return: 0|1
#
# example:
#  z.str.is.path_like "/usr/local/bin"
#  # return: 0
#  z.str.is.path_like "~/documents"
#  # return: 0
#  z.str.is.path_like "./script.sh"
#  # return: 0
#  z.str.is.path_like "../config"
#  # return: 0
#  z.str.is.path_like "."
#  # return: 0
#  z.str.is.path_like ".."
#  # return: 0
#  z.str.is.path_like "not/a/path"
#  # return: 1
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
