# 十進整数を数値順に並べ、元の表記を保持する
#
# $by?: 先頭に指定する並び順（asc|desc、既定: asc）
# $@: 並べる整数。符号・先頭ゼロを許可する
# REPLY: 整列した配列
# return: 0|1
#
# example:
#  z.arr.sort.numeric by=asc 10 -2 0 3
#  # REPLY: ("-2" "0" "3" "10")
z.arr.sort.numeric() {
  local sort_by=asc
  if z.str.start_with "${1-}" "by="; then
    z.str.remove.prefix "$1" "by="
    sort_by=$REPLY
    shift
  fi
  local values=("$@")

  z.arr.sort.numeric._keys "${values[@]}" || return 1
  local keys=("${REPLY[@]}")

  case $sort_by in
  asc)
    keys=("${(@o-n)keys}")
    ;;
  desc)
    keys=("${(@O-n)keys}")
    ;;
  *)
    return 1
    ;;
  esac

  local result=()
  local key
  for key in "${keys[@]}"; do
    result+=("${values[${key##*:}]}")
  done

  REPLY=("${result[@]}")
}
