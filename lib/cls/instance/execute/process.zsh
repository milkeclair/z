# Update a restored scalar or array while keeping its native parameter flags.
#
# $1: attribute name
# $@?: new value or array elements
# REPLY: unchanged
# return: 0|1
z.cls.instance.execute.set() {
  local z_cls_name=$1

  shift

  if [[ ${(tP)z_cls_name} == *array* || ${(tP)z_cls_name} == *association* ]]; then
    set -A "$z_cls_name" "$@"
  else
    z.int.is.eq $# 1 || return 1

    : ${(P)z_cls_name::=$1}
  fi
}
