# Enumerate the public and reference commands for one class instance.
#
# $1: class name
# $2: public binding name
# $3: opaque instance reference
# REPLY: array of command names, including an empty array for an empty class
# return: 0
z.cls.instance.commands() {
  local __z_cls_class=$1
  local __z_cls_binding=$2
  local __z_cls_id=$3
  local -a __z_cls_wrappers=()
  local __z_cls_prefix
  local __z_cls_member

  for __z_cls_prefix in "$__z_cls_binding" "$__z_cls_id"; do
    for __z_cls_member in ${=z_cls_class_methods[$__z_cls_class]}; do
      __z_cls_wrappers+=("$__z_cls_prefix.$__z_cls_member")
    done
    for __z_cls_member in ${=z_cls_class_attrs[$__z_cls_class]}; do
      __z_cls_wrappers+=("$__z_cls_prefix.$__z_cls_member.get")
      __z_cls_wrappers+=("$__z_cls_prefix.$__z_cls_member.set")
    done
  done

  REPLY=("${__z_cls_wrappers[@]}")
}
