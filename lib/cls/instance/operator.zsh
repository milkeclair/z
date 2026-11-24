# 再利用や削除の前に、コマンドの本体が登録済みの内容と一致するか検証する。
#
# $1: 生成済みのコマンド名
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: object.incrementを共有本体から登録済みで、利用者が置き換えていない
#  z.cls.instance._owns object.increment
#  # return: 0
z.cls.instance._owns() {
  local program=${functions[$1]-}
  local suffix=${1#*.}
  local expected_program=${z_cls_dispatch_programs[$suffix]-}

  # 関数本体の角括弧などをパターンにせず、文字列として照合する。
  setopt localoptions noglobsubst
  z.is.not.null "$program" && z.is.eq "$program" "$expected_program"
}
