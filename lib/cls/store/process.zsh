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
  z.is.eq "${z_cls_store_ready:-0}" 1 && z.var.exists z_cls_dispatch_programs && return 0

  zmodload zsh/parameter

  z.var.exists z_cls_classes || typeset -gA z_cls_classes
  z.var.exists z_cls_class_attrs || typeset -gA z_cls_class_attrs
  z.var.exists z_cls_class_methods || typeset -gA z_cls_class_methods
  z.var.exists z_cls_defaults || typeset -gA z_cls_defaults
  z.var.exists z_cls_bodies || typeset -gA z_cls_bodies

  z.var.exists z_cls_instances || typeset -gA z_cls_instances
  z.var.exists z_cls_values || typeset -gA z_cls_values
  z.var.exists z_cls_members || typeset -gA z_cls_members
  z.var.exists z_cls_wrapper_refs || typeset -gA z_cls_wrapper_refs
  z.var.exists z_cls_dispatch_programs || typeset -gA z_cls_dispatch_programs
  z.var.exists z_cls_next_id || typeset -gi z_cls_next_id=0
  z.var.exists z_cls_active || typeset -gA z_cls_active

  z.var.exists z_cls_drawing || typeset -g +x z_cls_drawing=''
  z.var.exists z_cls_capture_method || typeset -g +x z_cls_capture_method=''

  typeset -gi +x z_cls_store_ready=1
}

# 通常のスカラーと十進整数を、復元可能な宣言へ引用して保存する。
#
# $1: 実体参照
# $2: 属性名
# $3: 保存する値
# $4?: 宣言フラグ（既定: --、整数は-i）
# REPLY: null
# return: 0
#
# example:
#  # 前提: z.cls.store._ensureで保存領域を初期化している
#  z.cls.store._scalar object label "two words"
#  # return: 0
#  # 変更後: z_cls_values[object:label]="typeset -- label='two words'"
z.cls.store._scalar() {
  local declaration_flag=${4:---}
  local -a REPLY=()

  z.arr.quote style=single "$3"

  z_cls_values[$1:$2]="typeset $declaration_flag $2=$REPLY[1]"
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
#  # 前提: Counterを定義中
#  z.cls.store._method value class=Counter body='REPLY=0'
#  # return: 0
#  # 変更後: Counterのメソッド一覧にvalueを加え、本体にREPLY=0を保存
z.cls.store._method() {
  local REPLY=""
  z.arg.named class "${@:2}" && local class_name=$REPLY
  z.arg.named body "${@:2}" && local body=$REPLY

  z_cls_bodies[$class_name:$1]=$body
  z_cls_class_methods[$class_name]+="$1 "
}

# 未公開クラスが登録した属性とメソッドを破棄する。
#
# $1: 定義中のクラス名
# REPLY: null
# return: 0
#
# example:
#  # 前提: Counterの公開前にcountとincrementを宣言している
#  z.cls.store._discard Counter
#  # return: 0
#  # 変更後: Counterの属性、初期値、メソッド本体を破棄
z.cls.store._discard() {
  local -a REPLY=()
  local member

  z.cls.store._names "${z_cls_class_attrs[$1]-}"
  for member in "${REPLY[@]}"; do
    unset "z_cls_defaults[$1:$member]"
  done

  z.cls.store._names "${z_cls_class_methods[$1]-}"
  for member in "${REPLY[@]}"; do
    unset "z_cls_bodies[$1:$member]"
  done

  unset "z_cls_class_attrs[$1]" "z_cls_class_methods[$1]"
}
