# 文字列が空でないか確認する
#
# $1: 文字列
# REPLY: null
# 0|1を返す
#
# example:
#  z.str.is.not.empty ""
#  z.str.is.not.empty "hello"
z.str.is.not.empty() {
  local value=$1

  [[ -n $value ]]
}

# 文字列が正規表現に一致しないか確認する
#
# $1: 文字列
# $2: 正規表現
# REPLY: null
# 0|1を返す
#
# example:
#  z.str.is.not.match "hello" "^h.*o$"  #=> 1 (false)
#  z.str.is.not.match "hello" "^H.*O$"  #=> 0 (true, case-sensitive)
z.str.is.not.match() {
  local string=$1
  local regex=$2

  ! z.str.is.match "$string" "$regex"
}

# 文字列がパスの形式ではないか確認する
#
# $1: 文字列
# REPLY: null
# 0|1を返す
#
# example:
#  z.str.is.not.path_like "/usr/local/bin"  #=> 1 (false)
#  z.str.is.not.path_like "~/documents"     #=> 1 (false)
#  z.str.is.not.path_like "./script.sh"     #=> 1 (false)
#  z.str.is.not.path_like "../config"       #=> 1 (false)
#  z.str.is.not.path_like "."               #=> 1 (false)
#  z.str.is.not.path_like ".."              #=> 1 (false)
#  z.str.is.not.path_like "not/a/path"      #=> 0 (true)
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
