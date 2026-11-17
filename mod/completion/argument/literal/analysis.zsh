# 型アノテーション内の引用された許可値を1つ読み、未読部分も返す
#
# $1: 許可値から始まるアノテーション
# REPLY: 復号した許可値、閉じ引用符の後ろの記述
# return: 引用が閉じていれば0、それ以外は1
#
# example:
#  z.completion.argument.literal._read "'a:b' | 'other']"
#  # REPLY: ("a:b" " | 'other']")
z.completion.argument.literal._read() {
  local text=$1
  local quote=$text[1]
  z.arr.includes target="$quote" "'" '"' || return 1
  local cursor=2
  local value=""

  while z.int.is.lteq "$cursor" "${#text}"; do
    local char=$text[$cursor]
    if z.is.eq "$char" "$quote"; then
      REPLY=("$value" "${text[$((cursor + 1)),-1]}")
      return 0
    fi

    local next=$text[$((cursor + 1))]
    if z.is.eq "$char" '\' && z.arr.includes target="$next" "$quote" '\'; then
      char=$next
      ((cursor++))
    fi
    value+=$char
    ((cursor++))
  done

  REPLY=""
  return 1
}
