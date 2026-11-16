# Read a restored attribute without normalizing its value or array shape.
#
# $1: attribute name
# REPLY: exact scalar or array value
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
