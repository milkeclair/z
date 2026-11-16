# 文字列に部分文字列が含まれるか確認する
#
# $1: 文字列
# $2: 部分文字列
# REPLY: null
# return: 0|1
#
# example:
#  z.str.includes "hello world" "lo wo"
#  # return: 0
#  z.str.includes "hello world" "LO WO"
#  # return: 1
z.str.includes() {
  local string=$1
  local substring=$2

  [[ $string == *$substring* ]]
}

# 文字列に部分文字列が含まれないか確認する
#
# $1: 文字列
# $2: 部分文字列
# REPLY: null
# return: 0|1
#
# example:
#  z.str.excludes "hello world" "lo wo"
#  # return: 1
#  z.str.excludes "hello world" "LO WO"
#  # return: 0
z.str.excludes() {
  local string=$1
  local substring=$2

  [[ $string != *$substring* ]]
}

# 文字列が接頭辞で始まるか確認する
#
# $1: 文字列
# $2: 接頭辞
# REPLY: null
# return: 0|1
#
# example:
#  z.str.start_with "hello world" "hello"
#  # return: 0
#  z.str.start_with "hello world" "HELLO"
#  # return: 1
z.str.start_with() {
  local string=$1
  local prefix=$2

  [[ $string == $prefix* ]]
}

# 文字列が接尾辞で終わるか確認する
#
# $1: 文字列
# $2: 接尾辞
# REPLY: null
# return: 0|1
#
# example:
#  z.str.end_with "hello world" "world"
#  # return: 0
#  z.str.end_with "hello world" "WORLD"
#  # return: 1
z.str.end_with() {
  local string=$1
  local suffix=$2

  [[ $string == *$suffix ]]
}
