# 復元済みの属性について、値とスカラー・配列の形式を保って取得する。
#
# $1: 属性名
# REPLY: 元の形式を保ったスカラーまたは配列の値
# return: 0|1
z.cls.instance.execute._get() {
  local z_cls_name=$1

  shift
  z.int.is.zero $# || return 1

  local z_cls_type=${(tP)z_cls_name}

  if z.str.includes "$z_cls_type" array || z.str.includes "$z_cls_type" association; then
    REPLY=("${(@P)z_cls_name}")
  else
    REPLY=${(P)z_cls_name}
  fi
}
