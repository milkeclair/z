# インスタンスIDから属性を読み、値をREPLYへ返す。
#
# $1: インスタンス参照
# $2: 属性名
# REPLY: 属性値
# return: 0|1
#
# example:
#  z.cls.draw Counter
#    z.cls.attr label default=hello
#  z.cls.drew
#  local object=""
#  z.cls.new Counter object
#  z.cls.instance.call._get "$object" label
#  # REPLY: hello
#  # return: 0
z.cls.instance.call._get() {
  local instance_id=${z_cls_references[$1]-$1}
  z.cls.instance.call._validate "$instance_id" "$1" || return
  z.is.not.eq "$#" 2 && return 1

  local attribute_key="$instance_id:$2"
  if (( ${+z_cls_values[$attribute_key]} )); then
    z.cls.instance.call._access "$instance_id" get "$2"
    return
  fi

  if (( ${+z_cls_scalars[$attribute_key]} )); then
    REPLY=$z_cls_scalars[$attribute_key]
    return 0
  fi

  local default_key="${z_cls_instances[$instance_id]}:$2"
  (( ${+z_cls_defaults[$default_key]} )) || return 1

  REPLY=$z_cls_defaults[$default_key]
}
