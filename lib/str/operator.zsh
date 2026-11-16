# 文字列に部分文字列が含まれるか確認する
#
# $1: 文字列
# $2: 部分文字列
# REPLY: null
# 0|1を返す
#
# example:
#  z.str.includes "hello world" "lo wo"  #=> 0 (true)
#  z.str.includes "hello world" "LO WO"  #=> 1 (false, case-sensitive)
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
# 0|1を返す
#
# example:
#  z.str.excludes "hello world" "lo wo"  #=> 1 (false)
#  z.str.excludes "hello world" "LO WO"  #=> 0 (true, case-sensitive)
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
# 0|1を返す
#
# example:
#  z.str.start_with "hello world" "hello"  #=> 0 (true)
#  z.str.start_with "hello world" "HELLO"  #=> 1 (false, case-sensitive)
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
# 0|1を返す
#
# example:
#  z.str.end_with "hello world" "world"  #=> 0 (true)
#  z.str.end_with "hello world" "WORLD"  #=> 1 (false, case-sensitive)
z.str.end_with() {
  local string=$1
  local suffix=$2

  [[ $string == *$suffix ]]
}
