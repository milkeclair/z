# code型アノテーションを読み、後続の記述と許可値を返す
#
# $1: 型アノテーションから始まる記述
# REPLY: 閉じ角括弧の後ろの記述、許可値
# return: code型アノテーションなら0、それ以外は1
#
# example:
#  z.completion.argument.type._read "[code | 'noop']: commands"
#  # REPLY: (": commands" "noop")
z.completion.argument.type._read() {
  z.str.start_with "$1" '[code' || return 1
  z.str.remove.prefix "$1" '[code'
  local remaining=$REPLY
  local literals=()

  while true; do
    z.str.trim "$remaining"
    remaining=$REPLY
    if z.str.start_with "$remaining" ']'; then
      z.str.remove.prefix "$remaining" ']'
      REPLY=("$REPLY" "${literals[@]}")
      return 0
    fi

    z.str.start_with "$remaining" '|' || return 1
    z.str.remove.prefix "$remaining" '|'
    z.str.trim "$REPLY"
    z.completion.argument.literal._read "$REPLY" || return 1
    literals+=("$REPLY[1]")
    remaining=$REPLY[2]
  done
}
