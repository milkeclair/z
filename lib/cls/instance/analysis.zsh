# 実体の変数名と参照から呼べるコマンド名を列挙する。
#
# $1: クラス名
# $2: 実体の参照を持つ変数名
# $3: 実体参照
# REPLY: コマンド名の配列。メンバーがない場合は空配列
# return: 0
#
# example:
#  # 前提: Counterは属性countだけを持つ
#  z.cls.instance._commands Counter counter ref
#  # REPLY: ("counter.count.get" "counter.count.set" "ref.count.get" "ref.count.set")
#  # return: 0
z.cls.instance._commands() {
  local class_name=$1
  local binding=$2
  local instance_id=$3
  local -a wrappers=()
  local prefix
  local member

  for prefix in "$binding" "$instance_id"; do
    for member in ${=z_cls_class_methods[$class_name]}; do
      wrappers+=("$prefix.$member")
    done

    for member in ${=z_cls_class_attrs[$class_name]}; do
      wrappers+=("$prefix.$member.get")
      wrappers+=("$prefix.$member.set")
    done
  done

  REPLY=("${wrappers[@]}")
}
