# 実体IDで呼び出すメソッドと属性のコマンドを列挙する。
#
# $1: クラス名
# $2: 実体参照
# REPLY: コマンド名の配列。メンバーがない場合は空配列
# return: 0
#
# example:
#  # 前提: Counterは属性countだけを持つ
#  z.cls.instance._commands Counter ref
#  # REPLY: ("ref.count.get" "ref.count.set")
#  # return: 0
z.cls.instance._commands() {
  local class_name=$1
  local reference=$2

  if z.var.exists "z_cls_command_suffixes[$class_name]"; then
    local -a suffixes=(${=z_cls_command_suffixes[$class_name]})
    REPLY=("${(@)suffixes/#/$reference}")
    return 0
  fi

  local -a wrappers=()
  local member

  for member in ${=z_cls_class_methods[$class_name]}; do
    wrappers+=("$reference.$member")
  done

  for member in ${=z_cls_class_attrs[$class_name]}; do
    wrappers+=("$reference.$member.get" "$reference.$member.set")
  done

  REPLY=("${wrappers[@]}")
}
