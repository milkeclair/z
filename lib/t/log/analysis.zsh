# テストの見出しを整形する
#
# $1: インデント
# $2: 色
# $3: メッセージ
# REPLY: 整形済みの見出し
# return: null
#
# example:
#  z.t._log.format "  " green "My Test Suite"
#  # REPLY: $'\033[32m  My Test Suite\033[0m'
z.t._log.format() {
  local indentation=$1
  local color_name=$2

  REPLY="$3"
  local message="$indentation$REPLY"

  local code=""
  for code in ${(v)z_color_palette}; do
    message=${message//$code/}
  done

  local prefix=$z_color_palette[$color_name]
  if [[ -n "$prefix" ]]; then
    REPLY="$prefix$message$z_color_palette[reset]"
  else
    REPLY=$message
  fi
}
