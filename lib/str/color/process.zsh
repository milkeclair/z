# 文字列からカラーコードを取り除く
#
# $1: カラーコードを含む文字列
# REPLY: カラーコードを除いた文字列
# return: null
#
# example:
#  z.str.color.strip $'\033[31mHello\033[0m'
#  # REPLY: "Hello"
z.str.color.strip() {
  local message=$1

  local stripped=$message
  z.hash.values z_color_palette
  for code in $REPLY; do
    stripped=${stripped//$code/}
  done

  REPLY=$stripped
}

# 文字列にカラーコードを付ける
#
# $color: 色
# $message: 装飾する文字列
# REPLY: 装飾した文字列
# return: null
#
# example:
#  z.str.color.decorate color=red message="Hello"
#  # REPLY: $'\033[31mHello\033[0m'
z.str.color.decorate() {
  z.arg.named color $@ && local color=$REPLY
  z.arg.named message $@ && local message=$REPLY

  z.str.color.strip $message
  local plain=$REPLY

  z.str.color $color
  local color_prefix=$REPLY

  if z.is.not.null $color_prefix; then
    z.str.color reset
    local reset=$REPLY
    REPLY="${color_prefix}${plain}${reset}"
  else
    REPLY=$plain
  fi
}

# 文字列に赤色を付ける
#
# $1: 装飾する文字列
# REPLY: 装飾した文字列
# return: null
#
# example:
#  z.str.color.red "Hello"
#  # REPLY: $'\033[31mHello\033[0m'
z.str.color.red() {
  local message=$1

  z.str.color.decorate color=red message=$message
}

# 文字列に緑色を付ける
#
# $1: 装飾する文字列
# REPLY: 装飾した文字列
# return: null
#
# example:
#  z.str.color.green "Hello"
#  # REPLY: $'\033[32mHello\033[0m'
z.str.color.green() {
  local message=$1

  z.str.color.decorate color=green message=$message
}

# 文字列に黄色を付ける
#
# $1: 装飾する文字列
# REPLY: 装飾した文字列
# return: null
#
# example:
#  z.str.color.yellow "Hello"
#  # REPLY: $'\033[33mHello\033[0m'
z.str.color.yellow() {
  local message=$1

  z.str.color.decorate color=yellow message=$message
}

# 文字列に青色を付ける
#
# $1: 装飾する文字列
# REPLY: 装飾した文字列
# return: null
#
# example:
#  z.str.color.blue "Hello"
#  # REPLY: $'\033[34mHello\033[0m'
z.str.color.blue() {
  local message=$1

  z.str.color.decorate color=blue message=$message
}

# 文字列にマゼンタを付ける
#
# $1: 装飾する文字列
# REPLY: 装飾した文字列
# return: null
#
# example:
#  z.str.color.magenta "Hello"
#  # REPLY: $'\033[35mHello\033[0m'
z.str.color.magenta() {
  local message=$1

  z.str.color.decorate color=magenta message=$message
}

# 文字列にシアンを付ける
#
# $1: 装飾する文字列
# REPLY: 装飾した文字列
# return: null
#
# example:
#  z.str.color.cyan "Hello"
#  # REPLY: $'\033[36mHello\033[0m'
z.str.color.cyan() {
  local message=$1

  z.str.color.decorate color=cyan message=$message
}

# 文字列に白色を付ける
#
# $1: 装飾する文字列
# REPLY: 装飾した文字列
# return: null
#
# example:
#  z.str.color.white "Hello"
#  # REPLY: $'\033[37mHello\033[0m'
z.str.color.white() {
  local message=$1

  z.str.color.decorate color=white message=$message
}
