# 宣言済みの変数がインスタンスの参照を受け取れるか判定する。
#
# $1: 代入先変数名
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.store._ensure
#  local counter=""
#  z.cls.owner.is._writable counter
#  # return: 0
z.cls.owner.is._writable() {
  if ! z.cls.is._attribute "$1"; then
    return 1
  fi

  case ${parameters[$1]-} in
    *readonly*|*tied*|*upper*|*lower*|*left*|*right_blanks*|*right_zeros*)
      return 1
      ;;
    scalar|scalar-*)
      ;;
    *)
      return 1
      ;;
  esac

  local REPLY=""
  z.var.get "$1"
  z.is.null "$REPLY[1]" || ! z.var.exists "z_cls_references[$REPLY[1]]"
}

# 指定した変数が参照先インスタンスの現在の所有者か判定する。
#
# $1: 所有者か確認する変数名
# $instance: 解決済みのインスタンスID
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw CurrentCounter
#  z.cls.drew
#  local counter=""
#  z.cls.new CurrentCounter counter
#  z.cls.owner.is._current counter instance="$counter"
#  # return: 0
z.cls.owner.is._current() {
  local z_cls_variable=$1
  shift

  local REPLY=""
  z.arg.named instance "$@" && local z_cls_instance_id=$REPLY
  local z_cls_marker=${z_cls_owner_markers[$z_cls_instance_id]-}

  if ! z.var.exists "$z_cls_marker"; then
    return 1
  fi

  if z.str.excludes "${parameters[$z_cls_variable]-}" tied; then
    return 1
  fi

  local declaration=$(builtin typeset -p -- "$z_cls_variable")
  z.str.split.shell "$declaration"
  local -a words=("${REPLY[@]}")
  local -i index=2

  while z.str.start_with "${words[index]-}" -; do
    (( ++index ))
  done

  if z.is.not.eq "${words[index]-}" "$z_cls_variable"; then
    return 1
  fi

  z.str.start_with "${words[index+1]-}" "$z_cls_marker="
}
