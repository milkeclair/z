# 実体の変数名と参照から呼べるコマンド名を列挙する。
#
# $1: クラス名
# $2: 実体の参照を持つ変数名
# $3: 実体参照
# REPLY: コマンド名の配列。メンバーがない場合は空配列
# return: 0
z.cls.instance._commands() {
  local z_cls_class=$1
  local z_cls_binding=$2
  local z_cls_id=$3
  local -a z_cls_wrappers=()
  local z_cls_prefix
  local z_cls_member

  for z_cls_prefix in "$z_cls_binding" "$z_cls_id"; do
    for z_cls_member in ${=z_cls_class_methods[$z_cls_class]}; do
      z_cls_wrappers+=("$z_cls_prefix.$z_cls_member")
    done
    for z_cls_member in ${=z_cls_class_attrs[$z_cls_class]}; do
      z_cls_wrappers+=("$z_cls_prefix.$z_cls_member.get")
      z_cls_wrappers+=("$z_cls_prefix.$z_cls_member.set")
    done
  done

  REPLY=("${z_cls_wrappers[@]}")
}
