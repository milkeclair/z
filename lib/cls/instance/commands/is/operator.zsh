# 再利用や削除の前に、コマンドの本体が登録済みの内容と一致するか検証する。
#
# $1: 生成済みのコマンド名
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.store._ensure
#  z.cls.instance.commands._install z_cls_12345_1.increment
#  z.cls.instance.commands.is._managed z_cls_12345_1.increment
#  # return: 0
z.cls.instance.commands.is._managed() {
  local program=${functions[$1]-}
  local suffix=${1#*.}
  local expected_program=${z_cls_dispatch_programs[$suffix]-}

  # 関数本体の角括弧などをパターンにせず、文字列として照合する。
  setopt localoptions noglobsubst
  z.is.not.null "$program" && z.is.eq "$program" "$expected_program"
}
