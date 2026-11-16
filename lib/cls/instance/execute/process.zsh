# Zshの属性フラグを保ちながら、復元済みのスカラーまたは配列を更新する。
#
# $1: 属性名
# $@?: 新しい値または配列の要素
# REPLY: 変更しない
# return: 0|1
z.cls.instance.execute._set() {
  local z_cls_name=$1

  shift

  local z_cls_type=${(tP)z_cls_name}

  if z.str.includes "$z_cls_type" array || z.str.includes "$z_cls_type" association; then
    set -A "$z_cls_name" "$@"
  else
    z.int.is.eq $# 1 || return 1

    : ${(P)z_cls_name::=$1}
  fi
}
