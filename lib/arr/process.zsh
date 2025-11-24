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
    z.return $(printf "%s\n" "${arr[@]}" | sort)
    ;;
  desc)
    z.return $(printf "%s\n" "${arr[@]}" | sort -r)
    ;;
  *)
    z.return ${arr[@]}
    z.io.error "z.arr.sort: invalid sort order: ${sort_by}"
    return 1
    ;;
  esac
}
