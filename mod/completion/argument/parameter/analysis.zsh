# 引数宣言の先頭から種類・名前・後続の記述を取得する
#
# $1: 前後の空白を除いた引数コメント
# REPLY: 種類、名前、後続の記述
# return: 引数の宣言なら0、それ以外は1
#
# example:
#  z.completion.argument.parameter._read '$code?: commands'
#  # REPLY: ("named" "code" ": commands")
z.completion.argument.parameter._read() {
  local declaration_pattern='^\$([A-Za-z_][A-Za-z0-9_]*|[0-9]+|[@*])\??'
  z.str.match "$1" "$declaration_pattern"
  local declaration=$REPLY
  z.is.null "$declaration" && return 1

  z.str.remove.prefix "$1" "$declaration"
  z.str.trim "$REPLY"
  local remaining=$REPLY
  z.str.remove.prefix "$declaration" '$'
  z.str.remove.suffix "$REPLY" '?'
  local marker=$REPLY
  local kind=named

  if z.int.is.match "$marker"; then
    z.int.is.positive "$marker" || return 1
    marker=$((10#$marker))
    kind=positional
  elif z.arr.includes target="$marker" '@' '*'; then
    kind=rest
  fi

  REPLY=("$kind" "$marker" "$remaining")
}
