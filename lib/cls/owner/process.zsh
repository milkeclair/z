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
  z.cls.instance._commands "$z_cls_instances[$z_cls_id]" "$z_cls_new_ref"
  local -a z_cls_new_commands=("${(@)REPLY}")

  z.cls.instance.commands._validate "${z_cls_new_commands[@]}" || return 1
  z.cls.instance.commands._install "${z_cls_new_commands[@]}" || return 1

  if ! z.cls.owner._bind "$z_cls_new_ref" "$z_cls_to" "$z_cls_id"; then
    z.cls.instance.commands._uninstall "${z_cls_new_commands[@]}"
    return 1
  fi

  unset "z_cls_references[$z_cls_old_ref]"
  z_cls_references[$z_cls_new_ref]=$z_cls_id
  z_cls_owner_refs[$z_cls_id]=$z_cls_new_ref
  z.cls.instance.commands._uninstall ${=z_cls_members[$z_cls_id]}
  z_cls_members[$z_cls_id]="${(j: :)z_cls_new_commands}"

  REPLY=$z_cls_new_ref
}

# 実体参照を代入し、代入先と同じ寿命の配列を所有者の目印にする。
#
# $1: 実体参照
# $2: 検証済みの代入先変数名
# $3?: 参照に対応する内部の実体ID
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: 保存領域を初期化済み
#  local counter=""
#  z.cls.owner._bind z_cls_12345_1 counter
#  # return: 0
#  # 変更後: counterはreadonlyの実体参照となり、所有者の目印が登録される
z.cls.owner._bind() {
  local z_cls_marker="z_cls_owner_$(( ++z_cls_next_owner_id ))"

  builtin typeset -gT "$2=$1" "$z_cls_marker" || return 1
  builtin typeset -gr -- "$2" || return 1
  z_cls_owner_markers[${3:-$1}]=$z_cls_marker
}
