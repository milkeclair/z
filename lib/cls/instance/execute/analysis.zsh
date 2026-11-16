# Read a restored attribute without normalizing its value or array shape.
#
# $1: attribute name
# REPLY: exact scalar or array value
# return: 0|1
z.cls.instance.execute.get() {
  local z_cls_name=$1

  shift
  z.int.is.zero $# || return 1

  if [[ ${(tP)z_cls_name} == *array* || ${(tP)z_cls_name} == *association* ]]; then
    REPLY=("${(@P)z_cls_name}")
  else
    REPLY=${(P)z_cls_name}
  fi
}
