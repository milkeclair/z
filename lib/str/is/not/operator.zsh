# 文字列が空でないか確認する
#
# $1: 文字列
# REPLY: null
# return: 0|1
#
# example:
#  z.str.is.not.empty ""
#  # return: 1
#  z.str.is.not.empty "hello"
#  # return: 0
z.str.is.not.empty() {
  local value=$1

  [[ -n $value ]]
}

# 文字列が正規表現に一致しないか確認する
#
# $1: 文字列
# $2: 正規表現
# REPLY: null
# return: 0|1
#
# example:
#  z.str.is.not.match "hello" "^h.*o$"
#  # return: 1
#  z.str.is.not.match "hello" "^H.*O$"
#  # return: 0
z.str.is.not.match() {
  local string=$1
  local regex=$2

  ! z.str.is.match "$string" "$regex"
}

# 文字列がパスの形式ではないか確認する
#
# $1: 文字列
# REPLY: null
# return: 0|1
#
# example:
#  z.str.is.not.path_like "/usr/local/bin"
#  # return: 1
#  z.str.is.not.path_like "~/documents"
#  # return: 1
#  z.str.is.not.path_like "./script.sh"
#  # return: 1
#  z.str.is.not.path_like "../config"
#  # return: 1
#  z.str.is.not.path_like "."
#  # return: 1
#  z.str.is.not.path_like ".."
#  # return: 1
#  z.str.is.not.path_like "not/a/path"
#  # return: 0
z.str.is.not.path_like() {
  local value=$1

  z.str.is.match "$value" "^/" && return 1
  z.str.is.match "$value" "^~" && return 1
  z.str.is.match "$value" "^\./" && return 1
  z.str.is.match "$value" "^\.\./" && return 1
  z.is.eq "$value" "." && return 1
  z.is.eq "$value" ".." && return 1

  return 0
}
