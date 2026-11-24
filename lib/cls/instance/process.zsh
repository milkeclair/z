# 呼び出しに使われた参照を有効なインスタンスIDへ解決する。
#
# $1: インスタンス参照
# $2: 呼び出し元で宣言した、インスタンスIDを受け取る変数名
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#  z.cls.drew
#  local counter=""
#  z.cls.new Counter counter
#  local instance_id=""
#  z.cls.instance._resolve "$counter" instance_id
#  # 変更後: instance_idにcounterと同じインスタンスIDを代入済み
#  # return: 0
z.cls.instance._resolve() {
  if z.is.null "${z_cls_instances[$1]-}"; then
    z.io.error "Instance reference $1 is not available in this scope."
    return 1
  fi

  if z.var.exists "z_cls_active[$1]" && z.is.not.eq "${z_cls_current_instance-}" "$1"; then
    z.io.error "Instance $1 is active in another instance call."
    return 1
  fi

  : "${(P)2::=$1}"
}

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

  z.cls.instance.commands._uninstall "$instance_id" "class=$class_name"

  z.cls.store._names "$z_cls_class_attrs[$class_name]"
  local attribute
  for attribute in "${REPLY[@]}"; do
    unset "z_cls_scalars[$instance_id:$attribute]"
  done

  unset "z_cls_instances[$instance_id]" "z_cls_active[$instance_id]"

  if z.is.eq "${#z_cls_instances}" 0; then
    z_cls_instances=()
    z_cls_scalars=()
    z_cls_active=()
  fi
}
