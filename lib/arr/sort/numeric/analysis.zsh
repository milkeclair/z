# 数値比較用に符号・先頭ゼロを揃え、元の位置を付ける
#
# $@: 十進整数
# REPLY: 「数値:位置」の配列
# return: 0|1
#
# example:
#  z.arr.sort.numeric._keys +02 -000 -0010
#  # REPLY: ("2:1" "0:2" "-10:3")
z.arr.sort.numeric._keys() {
  setopt localoptions extendedglob
  local result=()
  local index=0
  local value

  for value in "$@"; do
    z.int.is.match "$value" || return 1
    local number=${value#+}
    local magnitude=${${number#-}##0#}
    magnitude=${magnitude:-0}

    if z.str.start_with "$number" "-" && ! z.is.eq "$magnitude" 0; then
      magnitude="-$magnitude"
    fi

    index=$((index + 1))
    result+=("$magnitude:$index")
  done

  REPLY=("${result[@]}")
}
