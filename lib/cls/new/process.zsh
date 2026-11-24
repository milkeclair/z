# 実体の作成前に、引数と呼出元の代入先変数を検証する。
#
# $1: 公開済みのクラス名
# $2: 呼出元で宣言済みの、書き込み可能なスカラー変数名
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: Counterを公開済みで、objectをlocal -uで宣言している
#  z.cls.new._validate Counter object
#  # return: 1
#  # 変更後: objectと実体の登録は元のまま
z.cls.new._validate() {
  if z.is.not.eq "$#" 2 || z.is.null "${z_cls_classes[$1]:-}" || ! z.cls.is._attribute "$2"; then
    z.io.error "Expected an existing class and an ordinary instance variable name."
    return 1
  fi

  case ${parameters[$2]:-} in
    ""|*readonly*|*array*|*association*|*integer*|*float*|*tied*|*upper*|*lower*|*left*|*right_blanks*|*right_zeros*)
      z.io.error "Instance variable $2 must be a declared writable scalar."
      return 1
      ;;
  esac

  if z.is.not.null "${z_cls_instances[${(P)2:-}]:-}"; then
    z.io.error "Instance variable $2 already holds a reference."
    return 1
  fi

  return 0
}
