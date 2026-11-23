# 実体IDから属性を読み、値をREPLYへ返す。
#
# $1: 実体参照
# $2: 属性名
# REPLY: 属性値
# return: 0|1
#
# example:
#  # 前提: objectはlabelの値がhelloである実体の参照変数
#  z.cls.instance.call._get "$object" label
#  # REPLY: hello
#  # return: 0
z.cls.instance.call._get() {
  local z_cls_id=${z_cls_references[$1]:-$1}
  z.cls.instance.call._validate "$z_cls_id" "$1" || return 1

  local z_cls_key="$z_cls_id:$2"
  if (( ${+z_cls_values[$z_cls_key]} )); then
    z.cls.instance.call._access "$z_cls_id" get "$2" "${@:3}"
    return $?
  fi

  z.int.is.eq $# 2 || return 1

  if (( ${+z_cls_scalars[$z_cls_key]} )); then
    REPLY=$z_cls_scalars[$z_cls_key]
    return 0
  fi

  local z_cls_default_key="${z_cls_instances[$z_cls_id]}:$2"
  (( ${+z_cls_defaults[$z_cls_default_key]} )) || return 1

  REPLY=$z_cls_defaults[$z_cls_default_key]
}
