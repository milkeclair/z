# 保存領域のメンバー名や生成コマンド名を配列へ戻す。
#
# $1: 空白区切りで保存した名前の一覧
# REPLY: 名前の配列。空の一覧なら空配列
# return: 0
#
# example:
#  z.cls.store._names "value count.get count.set "
#  # REPLY: ("value" "count.get" "count.set")
#  # return: 0
z.cls.store._names() {
  if z.is.null "$1"; then
    REPLY=()
    return 0
  fi

  z.str.split.shell "$1"
}
