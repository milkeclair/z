# インスタンスの所有権を別の宣言済み変数へ移す。
#
# $from: 現在の所有変数名
# $to: インスタンスを受け取る宣言済みのスカラー変数名
# REPLY: 移したインスタンス参照
# return: 0|1
#
# example:
#  z.cls.draw MoveCounter
#    z.cls.attr count default=5
#  z.cls.drew
#  local counter=""
#  local saved=""
#  z.cls.new MoveCounter counter
#  z.cls.owner.move from=counter to=saved
#  # return: 0
#  $saved.count.get
#  # REPLY: 5
z.cls.owner.move() {
  z.cls.store._ensure

  # 呼出元の所有変数と移動先を参照できるよう、ローカル名に内部用の接頭辞を使う。
  z.arg.named from "$@" && local z_cls_from=$REPLY
  z.arg.named to "$@" && local z_cls_to=$REPLY

  if ! z.cls.is._attribute "$z_cls_from" || ! z.cls.owner.is._writable "$z_cls_to"; then
    z.io.error "Expected an owner and a declared writable destination variable."
    return 1
  fi

  local z_cls_old_reference=${(P)z_cls_from-}
  if ! z.cls.owner.is._current "$z_cls_from" "reference=$z_cls_old_reference"; then
    z.io.error "Instance variable $z_cls_from is not the current owner."
    return 1
  fi

  local z_cls_instance_id=${z_cls_references[$z_cls_old_reference]-$z_cls_old_reference}
  if z.is.not.null "${z_cls_active[$z_cls_instance_id]-}"; then
    z.io.error "Cannot move an active instance."
    return 1
  fi

  local z_cls_new_reference="z_cls_ref_${$}_$(( ++z_cls_next_reference ))"
  z.cls.instance._commands "$z_cls_instances[$z_cls_instance_id]" "reference=$z_cls_new_reference"
  local -a z_cls_new_commands=("${(@)REPLY}")

  z.cls.instance.commands._install "${z_cls_new_commands[@]}" || return

  if ! z.cls.owner._bind "$z_cls_new_reference" "to=$z_cls_to" "instance=$z_cls_instance_id"; then
    z.cls.instance.commands._uninstall "${z_cls_new_commands[@]}"
    return 1
  fi

  unset "z_cls_references[$z_cls_old_reference]"
  z_cls_references[$z_cls_new_reference]=$z_cls_instance_id
  z_cls_owner_refs[$z_cls_instance_id]=$z_cls_new_reference

  z.cls.store._names "$z_cls_members[$z_cls_instance_id]"
  z.cls.instance.commands._uninstall "${REPLY[@]}"

  z.arr.join "${z_cls_new_commands[@]}"
  z_cls_members[$z_cls_instance_id]=$REPLY

  REPLY=$z_cls_new_reference
}

# インスタンス参照を代入し、代入先と同じ寿命の配列を所有者のマークにする。
#
# $1: インスタンス参照
# $to: 検証済みの代入先変数名
# $instance?: 内部のインスタンスID（省略時はインスタンス参照と同じ）
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.store._ensure
#  local counter=""
#  z.cls.owner._bind counter_reference to=counter
#  # return: 0
#  z.var.exists "$z_cls_owner_markers[counter_reference]"
#  # return: 0
#  # 変更後: counter="counter_reference"。counterはreadonly
z.cls.owner._bind() {
  local z_cls_reference=$1
  shift

  local REPLY=""
  z.arg.named to "$@" && local z_cls_binding=$REPLY

  if z.is.null "$z_cls_binding"; then
    return 1
  fi

  local z_cls_marker="z_cls_owner_$(( ++z_cls_next_owner_id ))"

  builtin typeset -gT "$z_cls_binding=$z_cls_reference" "$z_cls_marker" || return 1
  builtin typeset -gr -- "$z_cls_binding" || return 1

  z.arg.named instance "$@" default="$z_cls_reference"
  z_cls_owner_markers[$REPLY]=$z_cls_marker
}
