# join array elements with a space
#
# $@: array elements
# REPLY: joined string
# return: null
#
# example:
#  z.arr.join "a" "b" "c" #=> REPLY="a b c"
z.arr.join() {
  local -a arr=($@)

  z.return "${(j: :)arr}"
}

# sort array elements
#
# $by?: sort by (asc|desc), default: asc
# $@: array elements
# REPLY: sorted array elements
# return: null
#
# example:
#  z.arr.sort by=asc "b" "c" "a" #=> REPLY=("a" "b" "c")
#  z.arr.sort by=desc "b" "c" "a" #=> REPLY=("c" "b" "a")
z.arr.sort() {
  z.arg.named by $@
  local sort_by=${REPLY:-asc}
  z.arg.named.shift by $@

  local arr=($REPLY)

  case $sort_by in
  asc)
    z.return ${(@o)arr}
    ;;
  desc)
    z.return ${(@O)arr}
    ;;
  *)
    z.return ${arr[@]}
    z.io.error "z.arr.sort: invalid sort order: ${sort_by}"
    return 1
    ;;
  esac
}

# remove duplicate elements from an array
#
# $@: array elements
# REPLY: array elements with duplicates removed
# return: null
#
# example:
#  z.arr.unique "a" "b" "a" "c" "b" #=> REPLY=("a" "b" "c")
z.arr.unique() {
  local arr=($@)
  local -A seen
  local result

  for item in ${arr[@]}; do
    if z.is_falsy ${seen[$item]}; then
      seen[$item]=true
      result+=($item)
    fi
  done

  z.return ${result[@]}
}
