# 引数があるか確認する
#
# $@: 対象の値
# REPLY: null
# return: 0|1
#
# example:
#  z.arg.is.present "a" "b" "c" #=> 0
#  z.arg.is.present             #=> 1
z.arg.is.present() {
  local args=($@)

  z.int.is.gt $#args 0
}

# 引数がないか確認する
#
# $@: 対象の値
# REPLY: null
# return: 0|1
#
# example:
#  z.arg.is.empty "a" "b" "c" #=> 1
#  z.arg.is.empty             #=> 0
z.arg.is.empty() {
  local args=($@)

  z.int.is.eq $#args 0
}

# 引数の個数を検証する
#
# $length: 必要な最小個数
# $@: 引数
# REPLY: null
# return: 0|1
#
# example:
#  z.arg.is.valid "a" "b" "c" length=2 #=> 0
#  z.arg.is.valid "a" "b" "c" length=4 #=> 1
z.arg.is.valid() {
  z.arg.named length $@ && local length=$REPLY
  z.arg.named.shift length $@ && local args=($REPLY)
  local message="Expected at least $length arguments, but got ${#args}"

  if z.int.is.lt ${#args} $length; then
    z.is.eq $z_mode test || z.io.error $message
    return 1
  else
    return 0
  fi
}
