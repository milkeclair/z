# 指定インデックスの引数を取得する（1始まり）
#
# $index: 1始まりのインデックス
# $@: 引数
# REPLY: 指定した引数|null
# return: null
#
# example:
#  z.arg.get "a" "b" "c" index=2 #=> "b"
z.arg.get() {
  z.arg.named index "$@" && local index=$REPLY
  z.arg.named.shift index "$@"
  local args=("${REPLY[@]}")
  z.arr.count "${args[@]}"

  z.int.is.lteq $index $REPLY && REPLY=$args[$index] || REPLY=""
}

# 最初の引数を取得する
#
# $@: 引数
# REPLY: 最初の引数|null
# return: null
#
# example:
#  z.arg.first "a" "b" "c" #=> "a"
z.arg.first() {
  z.arg.get "$@" index=1
}

# 2番目の引数を取得する
#
# $@: 引数
# REPLY: 2番目の引数|null
# return: null
#
# example:
#  z.arg.second "a" "b" "c" #=> "b"
z.arg.second() {
  z.arg.get "$@" index=2
}

# 3番目の引数を取得する
#
# $@: 引数
# REPLY: 3番目の引数|null
# return: null
#
# example:
#  z.arg.third "a" "b" "c" #=> "c"
z.arg.third() {
  z.arg.get "$@" index=3
}

# 最後の引数を取得する
#
# $@: 引数
# REPLY: 最後の引数|null
# return: null
#
# example:
#  z.arg.last "a" "b" "c" #=> "c"
z.arg.last() {
  z.arr.count "$@"

  z.arg.get "$@" index=$REPLY
}
