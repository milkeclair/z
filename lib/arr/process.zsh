for join_file in ${z_root}/lib/arr/join/*.zsh; do
  source $join_file
done

# join array elements with a delimiter
#
# $delimiter?: delimiter, default: space
# $@: array elements
# REPLY: joined string
# return: null
#
# example:
#  z.arr.join "a" "b" "c" #=> REPLY="a b c"
z.arr.join() {
  z.arg.named delimiter $@ default=" " && local delimiter=$REPLY
  z.arg.named.shift delimiter $@ && local arr=($REPLY)

  local IFS=$delimiter
  z.return "${arr[*]}"
}

# split a string into an array by a delimiter
#
# $delimiter?: delimiter, default: space
# $@: string to split
# REPLY: array elements
# return: null
#
# example:
#  z.arr.split delimiter="," "a,b,c" #=> REPLY=("a" "b" "c")
#  z.arr.split "a b c"         #=> REPLY=("a" "b" "c")
z.arr.split() {
  z.arg.named delimiter $@ default=" " && local delimiter=$REPLY
  z.arg.named.shift delimiter $@
  local str=$REPLY
  local arr

  IFS=$delimiter read -rA arr <<<"$str"

  z.return ${arr[@]}
}

# perform global substitution on array elements
#
# $search: search string
# $replace: replace string
# $@: array elements
# REPLY: array elements after substitution
# return: null
#
# example:
#  z.arr.gsub search=a replace=x "a b a" "c a d" #=> REPLY=("x b x" "c x d")
z.arr.gsub() {
  local args=($@)

  z.arg.named search $args && local search=${REPLY}
  z.arg.named.shift search $args && args=($REPLY)

  z.arg.named replace $args && local replace=${REPLY}
  z.arg.named.shift replace $args && args=($REPLY)

  local result=()

  for item in ${args[@]}; do
    result+=(${item//$search/$replace})
  done

  z.return ${result[@]}
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
  z.arg.named by $@ default=asc
  local sort_by=$REPLY
  z.arg.named.shift by $@ && local arr=($REPLY)

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

# find differences between two arrays
#
# $base: base array (as a single string with spaces)
# $other: other array (as a single string with spaces)
# REPLY: array of differences
# return: null
#
# example:
#  z.arr.diff base="a b c" other="b c d" #=> REPLY=("a" "d")
z.arr.diff() {
  z.arg.named base $@ && local base=$REPLY
  z.arg.named other $@ && local other=$REPLY

  local base_arr=(${=base})
  local other_arr=(${=other})
  local -A base_set
  local -A other_set
  local result

  z.group "filling sets"; {
    for item in ${base_arr[@]}; do
      base_set[$item]=true
    done

    for item in ${other_arr[@]}; do
      other_set[$item]=true
    done
  }

  z.group "finding differences"; {
    for item in ${base_arr[@]}; do
      if z.is_falsy ${other_set[$item]}; then
        result+=($item)
      fi
    done

    for item in ${other_arr[@]}; do
      if z.is_falsy ${base_set[$item]}; then
        result+=($item)
      fi
    done
  }

  z.return ${result[@]}
}

# find intersection between two arrays
#
# $base: base array (as a single string with spaces)
# $other: other array (as a single string with spaces)
# REPLY: array of intersection elements
# return: null
#
# example:
#  z.arr.intersect base="a b c" other="b c d" #=> REPLY=("b" "c")
z.arr.intersect() {
  z.arg.named base $@ && local base=$REPLY
  z.arg.named other $@ && local other=$REPLY

  local base_arr=(${=base})
  local other_arr=(${=other})
  local -A base_set
  local -A other_set
  local result

  z.group "filling sets"; {
    for item in ${base_arr[@]}; do
      base_set[$item]=true
    done

    for item in ${other_arr[@]}; do
      other_set[$item]=true
    done
  }

  z.group "finding intersections"; {
    for item in ${base_arr[@]}; do
      if z.is_truthy ${other_set[$item]}; then
        result+=($item)
      fi
    done
  }

  z.return ${result[@]}
}

# find union of two arrays
#
# $base: base array (as a single string with spaces)
# $other: other array (as a single string with spaces)
# REPLY: array of union elements
# return: null
#
# example:
#  z.arr.union base="a b c" other="b c d e" #=> REPLY=("a" "b" "c" "d" "e")
z.arr.union() {
  z.arg.named base $@ && local base=$REPLY
  z.arg.named other $@ && local other=$REPLY

  local base_arr=(${=base})
  local other_arr=(${=other})
  local -A base_set
  local -A other_set
  local result

  z.group "filling sets"; {
    for item in ${base_arr[@]}; do
      base_set[$item]=true
    done

    for item in ${other_arr[@]}; do
      other_set[$item]=true
    done
  }

  z.group "finding union"; {
    for item in ${base_arr[@]}; do
      result+=($item)
    done

    for item in ${other_arr[@]}; do
      if z.is_falsy ${base_set[$item]}; then
        result+=($item)
      fi
    done
  }

  z.return ${result[@]}
}

# reverse the order of array elements
#
# $@: array elements
# REPLY: array elements in reverse order
# return: null
#
# example:
#  z.arr.reverse "a" "b" "c" #=> REPLY=("c" "b" "a")
z.arr.reverse() {
  local arr=($@)
  local result

  for ((i=${#arr[@]}; i>=1; i--)); do
    result+=(${arr[i]})
  done

  z.return ${result[@]}
}
