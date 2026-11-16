# 受け付ける名前付き引数の名前を取得する
#
# $1: 既定値の連想配列名
# REPLY: 受け付ける引数名の配列
# return: null
#
# example:
#  z.arg.parse._names values
z.arg.parse._names() {
  z.hash.keys $1 && local names=("${REPLY[@]}")
  local accepted_names=()
  local name

  for name in "${names[@]}"; do
    z.is.null "$name" && continue
    z.str.includes "$name" "=" && continue
    accepted_names+=("$name")
  done

  REPLY=("${accepted_names[@]}")
}
