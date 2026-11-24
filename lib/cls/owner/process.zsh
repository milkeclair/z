# 実体の所有権を別の宣言済み変数へ移す。
#
# $from: 現在の所有変数名
# $to: 実体を受け取る宣言済みのスカラー変数名
# REPLY: 移した実体参照
# return: 0|1
#
# example:
#  # 前提: counterがCounterの実体を所有している
#  local saved=""
#  z.cls.owner.move from=counter to=saved
#  # return: 0
#  # 変更後: savedから同じ実体を操作でき、counterの参照は失効する
z.cls.owner.move() {
  z.cls.store._ensure

  # 呼出元の所有変数と移動先を参照できるよう、ローカル名に内部用の接頭辞を使う。
  z.arg.named from "$@" && local z_cls_from=$REPLY
  z.arg.named to "$@" && local z_cls_to=$REPLY

  if ! z.cls.is._attribute "$z_cls_from" || ! z.cls.owner._writable "$z_cls_to"; then
    z.io.error "Expected an owner and a declared writable destination variable."
    return 1
  fi

  local z_cls_old_ref=${(P)z_cls_from:-}
  local z_cls_id=${z_cls_references[$z_cls_old_ref]:-$z_cls_old_ref}

  if ! z.cls.owner._is_current "$z_cls_from" "$z_cls_old_ref"; then
    z.io.error "Instance variable $z_cls_from is not the current owner."
    return 1
  fi

  if z.is.not.null "${z_cls_active[$z_cls_id]-}"; then
    z.io.error "Cannot move an active instance."
    return 1
  fi

  local z_cls_new_ref="z_cls_ref_${$}_$(( ++z_cls_next_reference ))"
  z.cls.instance._commands "$z_cls_instances[$z_cls_id]" "reference=$z_cls_new_ref"
  local -a z_cls_new_commands=("${(@)REPLY}")

  z.cls.instance.commands._validate "${z_cls_new_commands[@]}" || return 1
  z.cls.instance.commands._install "${z_cls_new_commands[@]}" || return 1

  if ! z.cls.owner._bind "$z_cls_new_ref" "to=$z_cls_to" "instance=$z_cls_id"; then
    z.cls.instance.commands._uninstall "${z_cls_new_commands[@]}"
    return 1
  fi

  unset "z_cls_references[$z_cls_old_ref]"
  z_cls_references[$z_cls_new_ref]=$z_cls_id
  z_cls_owner_refs[$z_cls_id]=$z_cls_new_ref

  z.cls.store._names "$z_cls_members[$z_cls_id]"
  z.cls.instance.commands._uninstall "${REPLY[@]}"

  z.arr.join "${z_cls_new_commands[@]}"
  z_cls_members[$z_cls_id]=$REPLY

  REPLY=$z_cls_new_ref
}

# 実体参照を代入し、代入先と同じ寿命の配列を所有者の目印にする。
#
# $1: 実体参照
# $to: 検証済みの代入先変数名
# $instance?: 内部の実体ID（省略時は実体参照と同じ）
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: 保存領域を初期化済み
#  local counter=""
#  z.cls.owner._bind z_cls_12345_1 to=counter
#  # return: 0
#  # 変更後: counterはreadonlyの実体参照となり、所有者の目印が登録される
z.cls.owner._bind() {
  local REPLY=""
  z.arg.named to "${@:2}" && local z_cls_binding=$REPLY
  z.arg.named instance "${@:2}" "default=$1" && local z_cls_instance=$REPLY

  z.is.null "$z_cls_binding" && return 1

  local z_cls_marker="z_cls_owner_$(( ++z_cls_next_owner_id ))"

  builtin typeset -gT "$z_cls_binding=$1" "$z_cls_marker" || return 1
  builtin typeset -gr -- "$z_cls_binding" || return 1
  z_cls_owner_markers[$z_cls_instance]=$z_cls_marker
}
