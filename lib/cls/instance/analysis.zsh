# 実体IDで呼び出すメソッドと属性のコマンドを列挙する。
#
# $1: クラス名
# $2: 実体参照
# $3?: readの場合はgetterと読み取り専用メソッドを列挙
# REPLY: コマンド名の配列。メンバーがない場合は空配列
# return: 0
#
# example:
#  # 前提: Counterは属性countだけを持つ
#  z.cls.instance._commands Counter ref
#  # REPLY: ("ref.count.get" "ref.count.set")
#  # return: 0
z.cls.instance._commands() {
  local z_cls_class=$1
  local z_cls_id=$2
  local -a z_cls_wrappers=()
  local z_cls_member

  for z_cls_member in ${=z_cls_class_methods[$z_cls_class]}; do
    if [[ ${3:-} == read && ${z_cls_method_access[$z_cls_class:$z_cls_member]:-read} == write ]]; then
      continue
    fi
    z_cls_wrappers+=("$z_cls_id.$z_cls_member")
  done

  for z_cls_member in ${=z_cls_class_attrs[$z_cls_class]}; do
    z_cls_wrappers+=("$z_cls_id.$z_cls_member.get")
    [[ ${3:-} == read ]] || z_cls_wrappers+=("$z_cls_id.$z_cls_member.set")
  done

  REPLY=("${z_cls_wrappers[@]}")
}
