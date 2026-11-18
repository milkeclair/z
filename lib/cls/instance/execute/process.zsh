# Zshの属性フラグを保ちながら、復元済みのスカラーまたは配列を更新する。
#
# $1: 属性名
# $@?: 新しい値または配列の要素
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: 呼出元でlocal -i count=4を宣言している
#  z.cls.instance.execute._set count '2 +'
#  # return: 1
#  # 変更後: countは4のまま
z.cls.instance.execute._set() {
  local REPLY=""
  local z_cls_name=$1

  shift

  local z_cls_type=${(tP)z_cls_name}

  z.str.includes "$z_cls_type" readonly && return 1

  if z.str.includes "$z_cls_type" association; then
    z.int.is.zero $(( $# % 2 )) || return 1
    set -A "$z_cls_name" "$@"
  elif z.str.includes "$z_cls_type" array; then
    set -A "$z_cls_name" "$@"
  else
    z.int.is.eq $# 1 || return 1

    if z.str.includes "$z_cls_type" integer || z.str.includes "$z_cls_type" float; then
      local z_cls_numeric=""

      if ! z_cls_numeric=$(
        : ${(P)z_cls_name::=$1}
        # 表示精度で丸めず、ロケールに依存しない数値表現だけを呼出元へ返す。
        local LC_ALL=C
        if z.str.includes "$z_cls_type" integer; then
          printf '%d' "$z_cls_name"
        else
          printf '%.17g' "$z_cls_name"
        fi
      ); then
        return 1
      fi

      case $z_cls_numeric in
        inf|-inf|nan|-nan)
          ;;
        *)
          local z_cls_numeric_pattern='^[+-]?[0-9]+([.][0-9]*)?([eE][+-]?[0-9]+)?$'
          z.str.is.match "$z_cls_numeric" "$z_cls_numeric_pattern" || return 1
          ;;
      esac

      : ${(P)z_cls_name::=$z_cls_numeric}
    else
      : ${(P)z_cls_name::=$1}
    fi
  fi
}
