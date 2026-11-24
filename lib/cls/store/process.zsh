# クラス定義、インスタンスの状態、本体収集用の管理変数を初期化する。
#
# REPLY: null
# return: 0
#
# example:
#  z.cls.store._ensure
#  # return: 0
#  # 変更後: z_cls_instances=()とz_cls_scalars=()を初期化済み
z.cls.store._ensure() {
  if z.is.eq "${z_cls_store_ready}" 1 && z.var.exists z_cls_dispatch_programs; then
    return 0
  fi

  zmodload zsh/parameter

  z.var.exists z_cls_classes || typeset -gA z_cls_classes
  z.var.exists z_cls_class_attrs || typeset -gA z_cls_class_attrs
  z.var.exists z_cls_class_methods || typeset -gA z_cls_class_methods
  z.var.exists z_cls_defaults || typeset -gA z_cls_defaults
  z.var.exists z_cls_bodies || typeset -gA z_cls_bodies

  z.var.exists z_cls_instances || typeset -gA z_cls_instances
  z.var.exists z_cls_scalars || typeset -gA z_cls_scalars
  z.var.exists z_cls_dispatch_programs || typeset -gA z_cls_dispatch_programs
  z.var.exists z_cls_next_id || typeset -gi z_cls_next_id=0
  z.var.exists z_cls_active || typeset -gA z_cls_active

  z.var.exists z_cls_drawing || typeset -g z_cls_drawing=''
  z.var.exists z_cls_capture_method || typeset -g z_cls_capture_method=''

  typeset -gi z_cls_store_ready=1
}

# クラスのメソッド名と実行する本体を保存する。
#
# $1: メソッド名
# $class: 定義中のクラス名
# $body [code]: メソッド本体
# REPLY: null
# return: 0
#
# example:
#  z.cls.draw Counter
#  z.cls.store._method value class=Counter body='REPLY=0'
#  # return: 0
#  # 変更後: Counterのメソッド一覧にvalueを加え、本体にREPLY=0を保存
z.cls.store._method() {
  local method_name=$1
  shift

  local REPLY=""
  z.arg.named class "$@" && local class_name=$REPLY
  z.arg.named body "$@" && local body=$REPLY

  z_cls_bodies[$class_name:$method_name]=$body
  z_cls_class_methods[$class_name]+="$method_name "
}

# 未公開クラスが登録した属性とメソッドを破棄する。
#
# $1: 定義中のクラス名
# REPLY: null
# return: 0
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#    z.cls.method increment 'REPLY=1'
#  z.cls.store._discard Counter
#  # return: 0
#  # 変更後: Counterの属性、初期値、メソッド本体を破棄
z.cls.store._discard() {
  local -a REPLY=()
  local member

  z.cls.store._names "$z_cls_class_attrs[$1]"
  for member in "${REPLY[@]}"; do
    unset "z_cls_defaults[$1:$member]"
  done

  z.cls.store._names "$z_cls_class_methods[$1]"
  for member in "${REPLY[@]}"; do
    unset "z_cls_bodies[$1:$member]"
  done

  unset "z_cls_class_attrs[$1]" "z_cls_class_methods[$1]"
}
