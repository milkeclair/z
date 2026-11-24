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

  z.str.includes "${(tP)1}" readonly && return 1

  case ${(tP)1} in
    association*)
      z.int.is.zero $(( ($# - 1) % 2 )) || return 1
      set -A "$1" "${@:2}"
      ;;
    array*)
      set -A "$1" "${@:2}"
      ;;
    integer*|float*)
      z.is.eq "$#" 2 || return 1

      if ! REPLY=$(
        : ${(P)1::=$2}
        # 表示精度で丸めず、ロケールに依存しない数値表現だけを呼出元へ返す。
        local LC_ALL=C
        case ${(tP)1} in
          integer*) printf '%d' "$1" ;;
          float*) printf '%.17g' "$1" ;;
        esac
      ); then
        return 1
      fi

      case $REPLY in
        inf|-inf|nan|-nan)
          ;;
        *)
          z.str.is.match "$REPLY" '^[+-]?[0-9]+([.][0-9]*)?([eE][+-]?[0-9]+)?$' || return 1
          ;;
      esac

      : ${(P)1::=$REPLY}
      ;;
    *)
      z.is.eq "$#" 2 || return 1
      : ${(P)1::=$2}
      ;;
  esac
}
