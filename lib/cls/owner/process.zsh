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
#  # 変更後: savedだけが実体の寿命を保持し、counterは借用参照になる
z.cls.owner.move() {
  z.cls.store._ensure
  z.arg.named from "$@" && local z_cls_from=$REPLY
  z.arg.named to "$@" && local z_cls_to=$REPLY

  if ! z.cls.is._attribute "$z_cls_from" || ! z.cls.owner._writable "$z_cls_to"; then
    z.io.error "Expected an owner and a declared writable destination variable."
    return 1
  fi

  local z_cls_id=${(P)z_cls_from:-}
  if ! z.cls.owner._is_current "$z_cls_from" "$z_cls_id"; then
    z.io.error "Instance variable $z_cls_from is not the current owner."
    return 1
  fi

  z.cls.owner._bind "$z_cls_id" "$z_cls_to" || return 1
  REPLY=$z_cls_id
}

# 実体参照を代入し、代入先と同じ寿命の配列を所有者の目印にする。
#
# $1: 実体参照
# $2: 検証済みの代入先変数名
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
  z_cls_owner_markers[$1]=$z_cls_marker
}
