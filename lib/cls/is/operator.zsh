# Check a class, instance, attribute, or method identifier.
#
# $1: identifier
# REPLY: unchanged
# return: 0|1
z.cls.is.name() {
  local pattern='^[A-Za-z_][A-Za-z0-9_]*$'
  [[ ${1:-} =~ $pattern && $1 != z_cls_* && $1 != __z_cls_* ]]
}

# Check that an attribute can be restored as an ordinary local parameter.
#
# $1: attribute name
# REPLY: unchanged
# return: 0|1
z.cls.is.attribute() {
  z.cls.is.name "${1:-}" &&
    [[ $1 != REPLY && $1 != reply && ${parameters[$1]:-} != *special* ]]
}
