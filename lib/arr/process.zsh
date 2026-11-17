# 配列の要素を区切り文字で結合する
#
# $delimiter?: 区切り文字（既定: 空白）
# $@: 配列の要素
# REPLY: 結合した文字列
# return: null
#
# example:
#  z.arr.join "a" "b" "c"
#  # REPLY: "a b c"
z.arr.join() {
  local -a input_args=("$@")
  local -A parsed_named=([delimiter]=" ")
  local -a parsed_args=()
  z.arg.parse input=input_args named=parsed_named rest=parsed_args || return 1

  local arr=("${parsed_args[@]}")
  local IFS=${parsed_named[delimiter]}
  REPLY="${arr[*]}"
}

# 文字列を区切りで分割して配列にする
#
# $delimiter?: 区切り文字（既定: 空白）
# $@: 分割する文字列
# REPLY: 配列の要素
# return: null
#
# example:
#  z.arr.split delimiter="," "a,b,c"
#  # REPLY: ("a" "b" "c")
#  z.arr.split "a b c"
#  # REPLY: ("a" "b" "c")
z.arr.split() {
  z.arg.named delimiter "$@" default=" " && local delimiter=$REPLY
  z.arg.named.shift delimiter "$@"
  local str=$REPLY
  local arr

  IFS=$delimiter read -rA arr <<<"$str"

  REPLY=("${arr[@]}")
}

# 配列の要素を全体的に置換する
#
# $search: 検索する文字列
# $replace: 置換後の文字列
# $@: 配列の要素
# REPLY: 置換後の配列の要素
# return: null
#
# example:
#  z.arr.gsub search=a replace=x "a b a" "c a d"
#  # REPLY: ("x b x" "c x d")
z.arr.gsub() {
  local args=("$@")

  z.arg.named search "${args[@]}" && local search=${REPLY}
  z.arg.named.shift search "${args[@]}" && args=("${REPLY[@]}")

  z.arg.named replace "${args[@]}" && local replace=${REPLY}
  z.arg.named.shift replace "${args[@]}" && args=("${REPLY[@]}")

  local result=()

  for item in "${args[@]}"; do
    result+=("${item//$search/$replace}")
  done

  REPLY=("${result[@]}")
}

# 配列の要素を整列する
#
# $by?: 並び順（asc|desc、既定: asc）
# $@: 配列の要素
# REPLY: 整列した配列の要素
# return: null
#
# example:
#  z.arr.sort by=asc "b" "c" "a"
#  # REPLY: ("a" "b" "c")
#  z.arr.sort by=desc "b" "c" "a"
#  # REPLY: ("c" "b" "a")
z.arr.sort() {
  local values=("$@")
  local supplied=("${(@M)values:#by=*}")
  local sort_by=${supplied[1]#by=}
  sort_by=${sort_by:-asc}
  local arr=("${(@)values:#by=*}")

  case $sort_by in
  asc)
    REPLY=("${(@o)arr}")
    ;;
  desc)
    REPLY=("${(@O)arr}")
    ;;
  *)
    REPLY=("${arr[@]}")
    z.io.error "z.arr.sort: invalid sort order: ${sort_by}"
    return 1
    ;;
  esac
}

# 配列の重複要素を取り除く
#
# $@: 配列の要素
# REPLY: 重複を除いた配列の要素
# return: null
#
# example:
#  z.arr.unique "a" "b" "a" "c" "b"
#  # REPLY: ("a" "b" "c")
z.arr.unique() {
  local arr=("$@")
  local -A seen
  local result=()

  for item in "${arr[@]}"; do
    if ! z.is.true ${seen[$item]}; then
      seen[$item]=true
      result+=("$item")
    fi
  done

  REPLY=("${result[@]}")
}

# 2つの配列の差分を求める
#
# $base: 基準の配列（空白区切りの1つの文字列）
# $other: 比較する配列（空白区切りの1つの文字列）
# REPLY: 差分の配列
# return: null
#
# example:
#  z.arr.diff base="a b c" other="b c d"
#  # REPLY: ("a" "d")
z.arr.diff() {
  z.arg.named base "$@" && local base=$REPLY
  z.arg.named other "$@" && local other=$REPLY

  local base_arr=(${=base})
  local other_arr=(${=other})
  local -A base_set
  local -A other_set
  local result=()

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
      if ! z.is.true ${other_set[$item]}; then
        result+=("$item")
      fi
    done

    for item in ${other_arr[@]}; do
      if ! z.is.true ${base_set[$item]}; then
        result+=("$item")
      fi
    done
  }

  REPLY=("${result[@]}")
}

# 2つの配列の積集合を求める
#
# $base: 基準の配列（空白区切りの1つの文字列）
# $other: 比較する配列（空白区切りの1つの文字列）
# REPLY: 積集合の要素の配列
# return: null
#
# example:
#  z.arr.intersect base="a b c" other="b c d"
#  # REPLY: ("b" "c")
z.arr.intersect() {
  z.arg.named base "$@" && local base=$REPLY
  z.arg.named other "$@" && local other=$REPLY

  local base_arr=(${=base})
  local other_arr=(${=other})
  local -A base_set
  local -A other_set
  local result=()

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
      if z.is.true ${other_set[$item]}; then
        result+=("$item")
      fi
    done
  }

  REPLY=("${result[@]}")
}

# 2つの配列の和集合を求める
#
# $base: 基準の配列（空白区切りの1つの文字列）
# $other: 比較する配列（空白区切りの1つの文字列）
# REPLY: 和集合の要素の配列
# return: null
#
# example:
#  z.arr.union base="a b c" other="b c d e"
#  # REPLY: ("a" "b" "c" "d" "e")
z.arr.union() {
  z.arg.named base "$@" && local base=$REPLY
  z.arg.named other "$@" && local other=$REPLY

  local base_arr=(${=base})
  local other_arr=(${=other})
  local -A base_set
  local -A other_set
  local result=()

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
      result+=("$item")
    done

    for item in ${other_arr[@]}; do
      if ! z.is.true ${base_set[$item]}; then
        result+=("$item")
      fi
    done
  }

  REPLY=("${result[@]}")
}

# 配列の要素を逆順に並べる
#
# $@: 配列の要素
# REPLY: 逆順に並べた配列の要素
# return: null
#
# example:
#  z.arr.reverse "a" "b" "c"
#  # REPLY: ("c" "b" "a")
z.arr.reverse() {
  local arr=("$@")
  local result=()

  for ((i=${#arr[@]}; i>=1; i--)); do
    result+=("${arr[i]}")
  done

  REPLY=("${result[@]}")
}

# 配列の一部を切り出す
#
# $offset?: 切り出し開始位置（0始まり）
# $to?: 切り出し終端のインデックス（その位置を含まない、0始まり）
# $@: 配列の要素
# REPLY: 切り出した配列の要素
# return: null
#
# example:
#  z.arr.slice offset=2 to=5 "a" "b" "c" "d" "e"
#  # REPLY: ("c" "d" "e")
z.arr.slice() {
  local args=("$@")
  z.arg.named offset "${args[@]}" && local offset=$REPLY
  z.arg.named to "${args[@]}" && local to=$REPLY
  z.arg.named.shift offset "${args[@]}" && args=("${REPLY[@]}")
  z.arg.named.shift to "${args[@]}" && args=("${REPLY[@]}")
  local arr=("${args[@]}")

  if z.is.not.null "$offset"; then
    if z.is.not.null "$to"; then
      REPLY=("${arr[@]:$offset:$((to - offset))}")
    else
      REPLY=("${arr[@]:$offset}")
    fi
  elif z.is.not.null "$to"; then
    REPLY=("${arr[@]:0:$to}")
  else
    REPLY=("${arr[@]}")
  fi
}
