# 実体IDで呼び出すメソッドと属性のコマンドを列挙する。
#
# $1: クラス名
# $2: 実体参照
# $3?: getの場合は属性の読み取り用コマンドだけを列挙
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

  if [[ ${3:-} != get ]]; then
    for z_cls_member in ${=z_cls_class_methods[$z_cls_class]}; do
      z_cls_wrappers+=("$z_cls_id.$z_cls_member")
    done
  fi

  for z_cls_member in ${=z_cls_class_attrs[$z_cls_class]}; do
    z_cls_wrappers+=("$z_cls_id.$z_cls_member.get")
    [[ ${3:-} == get ]] || z_cls_wrappers+=("$z_cls_id.$z_cls_member.set")
  done

  REPLY=("${z_cls_wrappers[@]}")
}
