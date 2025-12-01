for is_file in ${z_root}/lib/arr/is/*.zsh; do
  source ${is_file}
done

# check if array includes element
#
# $target: element to find
# $@: array elements
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.includes target=apple "banana" "apple" "cherry"  #=> 0 (true)
#  z.arr.includes target=grape "banana" "apple" "cherry"  #=> 1 (false)
z.arr.includes() {
  z.arg.named target $@ && local target=$REPLY
  z.arg.named.shift target $@
  local list=($REPLY)

  for item in ${list[@]}; do
    z.is.eq $item $target && return 0
  done

  return 1
}

# check if array excludes element
#
# $target: element to exclude
# $@: array elements
# REPLY: null
# return: 0|1
#
# example:
#  z.arr.excludes target=apple "banana" "apple" "cherry"  #=> 1 (false)
#  z.arr.excludes target=grape "banana" "apple" "cherry"  #=> 0 (true)
z.arr.excludes() {
  z.arg.named target $@ && local target=$REPLY
  z.arg.named.shift target $@
  local list=($REPLY)

  for item in ${list[@]}; do
    z.is.eq $item $target && return 1
  done

  return 0
}
