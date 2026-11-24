# 実体参照から呼び出すメソッドと属性のコマンド名を列挙する。
#
# $1: クラス名
# $reference?: 生成名の接頭辞となる実体参照。省略時は接尾辞だけを返す
# REPLY: コマンド名の配列。メンバーがない場合は空配列
# return: 0
#
# example:
#  # 前提: Counterは属性countだけを持つ
#  z.cls.instance._commands Counter reference=ref
#  # REPLY: ("ref.count.get" "ref.count.set")
#  # return: 0
z.cls.instance._commands() {
  local class_name=$1
  z.arg.named reference "${@:2}" && local reference=$REPLY

  local -a wrappers=()
  local member

  z.cls.store._names "${z_cls_class_methods[$class_name]-}"
  for member in "${REPLY[@]}"; do
    wrappers+=("$reference.$member")
  done

  z.cls.store._names "${z_cls_class_attrs[$class_name]-}"
  for member in "${REPLY[@]}"; do
    wrappers+=("$reference.$member.get" "$reference.$member.set")
  done

  REPLY=("${wrappers[@]}")
}
