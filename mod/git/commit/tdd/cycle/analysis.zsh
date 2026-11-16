# 有効なコミットサイクルの一覧
#
# REPLY: 有効なコミットサイクルの配列
# return: null
#
# example:
#  z.git.commit.tdd._cycle.list
#  # REPLY: ("red" "green")
z.git.commit.tdd._cycle.list() {
  local tdd_cycles=(
    red
    green
  )

  REPLY=("${tdd_cycles[@]}")
}
