# 宣言済みの変数が所有参照を受け取れるか検証する。
#
# $1: 代入先変数名
# REPLY: null
# return: 0|1
#
# example:
#  local counter=""
#  z.cls.owner._writable counter
#  # return: 0
z.cls.owner._writable() {
  z.cls.is._attribute "$1" || return 1

  case ${parameters[$1]:-} in
    *readonly*|*tied*|*upper*|*lower*|*left*|*right_blanks*|*right_zeros*)
      return 1
      ;;
    scalar|scalar-*)
      ;;
    *)
      return 1
      ;;
  esac

  local reference=${(P)1:-}
  z.is.null "$reference" && return 0

  local instance_id=${z_cls_references[$reference]:-$reference}
  z.is.null "${z_cls_instances[$instance_id]:-}"
}

# 指定した変数が実体の現在の所有変数か検証する。
#
# $1: 変数名
# $2: 実体参照
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: counterはnewで生成した実体の所有変数
#  z.cls.owner._is_current counter "$counter"
#  # return: 0
z.cls.owner._is_current() {
  local z_cls_id=${z_cls_references[$2]:-$2}
  z.is.eq "$2" "${z_cls_owner_refs[$z_cls_id]:-$z_cls_id}" || return 1

  local z_cls_marker=${z_cls_owner_markers[$z_cls_id]:-}
  z.is.not.null "$z_cls_marker" || return 1
  z.str.includes "${parameters[$1]:-}" tied || return 1

  local declaration=$(builtin typeset -p -- "$1")
  local REPLY=""
  z.str.split.shell "$declaration"
  local -a words=("${REPLY[@]}")
  local -i index=2
  while z.str.start_with "${words[index]:-}" -; do
    (( ++index ))
  done

  z.is.eq "${words[index]:-}" "$1" &&
    z.str.start_with "${words[index+1]:-}" "$z_cls_marker="
}
