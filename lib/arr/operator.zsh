# 配列に要素が含まれるか確認する
#
# $target: 検索する要素
# $@: 配列の要素
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.includes target=apple "banana" "apple" "cherry"
#  # return: 0
#  z.arr.includes target=grape "banana" "apple" "cherry"
#  # return: 1
z.arr.includes() {
  z.arg.named target $@ && local target=$REPLY
  z.arg.named.shift target $@
  local list=($REPLY)

  for item in ${list[@]}; do
    z.is.eq $item $target && return 0
  done

  return 1
}

# 配列に要素が含まれないか確認する
#
# $target: 除外する要素
# $@: 配列の要素
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.excludes target=apple "banana" "apple" "cherry"
#  # return: 1
#  z.arr.excludes target=grape "banana" "apple" "cherry"
#  # return: 0
z.arr.excludes() {
  z.arg.named target $@ && local target=$REPLY
  z.arg.named.shift target $@
  local list=($REPLY)

  for item in ${list[@]}; do
    z.is.eq $item $target && return 1
  done

  return 0
}
