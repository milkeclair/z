# インスタンスのコマンドと、変更した属性値を解放する。
#
# $1: 存在する非実行中のインスタンスID
# REPLY: null
# return: 0
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#  z.cls.drew
#  local counter=""
#  z.cls.new Counter counter
#  z.cls.instance._release "$counter"
#  # 変更後: counterのインスタンスと生成コマンドを解放済み
z.cls.instance._release() {
  local -a REPLY=()
  local instance_id=$1
  local class_name=$z_cls_instances[$instance_id]

  local reference=$z_cls_owner_refs[$instance_id]

  z.cls.instance.commands._uninstall "$reference" "class=$class_name"

  z.cls.store._names "$z_cls_class_attrs[$class_name]"
  local attribute
  for attribute in "${REPLY[@]}"; do
    unset "z_cls_scalars[$instance_id:$attribute]"
  done

  unset "z_cls_instances[$instance_id]" "z_cls_active[$instance_id]"
  unset "z_cls_references[$reference]" "z_cls_owner_refs[$instance_id]" "z_cls_owner_markers[$instance_id]"

  if z.int.is.zero "${#z_cls_instances}"; then
    z_cls_instances=()
    z_cls_scalars=()
    z_cls_active=()
    z_cls_references=()
    z_cls_owner_refs=()
    z_cls_owner_markers=()
  fi
}
