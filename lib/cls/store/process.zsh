# クラス定義、実体の状態、本体収集用の管理変数を初期化する。
#
# REPLY: null
# return: 0
#
# example:
#  # 前提: 保存領域は未初期化
#  z.cls.store._ensure
#  # return: 0
#  # 変更後: z_cls_instances=()とz_cls_values=()を初期化済み
z.cls.store._ensure() {
  if z.is.eq "${z_cls_store_ready:-0}" 1 &&
      z.var.exists z_cls_dispatch_programs && z.var.exists z_cls_owner_markers &&
      z.var.exists z_cls_scalars; then
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
  z.var.exists z_cls_values || typeset -gA z_cls_values
  z.var.exists z_cls_members || typeset -gA z_cls_members
  z.var.exists z_cls_wrapper_refs || typeset -gA z_cls_wrapper_refs
  z.var.exists z_cls_dispatch_programs || typeset -gA z_cls_dispatch_programs
  z.var.exists z_cls_next_id || typeset -gi z_cls_next_id=0
  z.var.exists z_cls_owner_markers || typeset -gA z_cls_owner_markers
  z.var.exists z_cls_next_owner_id || typeset -gi +x z_cls_next_owner_id=0
  z.var.exists z_cls_gc_allocations || typeset -gi +x z_cls_gc_allocations=0
  z.var.exists z_cls_active || typeset -gA z_cls_active
  z.var.exists z_cls_drawing || typeset -g +x z_cls_drawing=''
  z.var.exists z_cls_capture_method || typeset -g +x z_cls_capture_method=''

  typeset -gi +x z_cls_store_ready=1
}

# 実体のスカラー属性を文字列として保存する。
#
# $1: 実体参照
# $2: 属性名
# $3: 保存する値
# REPLY: null
# return: 0
#
# example:
#  z.cls.store._scalar object label "two words"
#  # return: 0
#  # 変更後: z_cls_scalars[object:label]="two words"
z.cls.store._scalar() {
  z_cls_scalars[$1:$2]=$3
  unset "z_cls_values[$1:$2]"
}

# クラスのメソッド一覧と、対応する本体を保存する。
#
# $1: 定義中のクラス名
# $2: メソッド名
# $3: メソッド本体
# REPLY: null
# return: 0
#
# example:
#  # 前提: Counterを定義中
#  z.cls.store._method Counter value 'REPLY=0'
#  # return: 0
#  # 変更後: Counterのメソッド一覧にvalueを加え、本体にREPLY=0を保存
z.cls.store._method() {
  z_cls_bodies[$1:$2]=$3
  z_cls_class_methods[$1]+="$2 "
}
