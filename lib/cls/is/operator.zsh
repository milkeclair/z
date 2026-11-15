# Check a class, instance, attribute, or method identifier.
#
# $1: identifier
# REPLY: unchanged
# return: 0|1
z.cls.is.name() {
  local name=${1:-}
  local pattern='^[A-Za-z_][A-Za-z0-9_]*$'

  z.str.is.match "$name" "$pattern" &&
    ! z.str.start_with "$name" z_cls_ &&
    ! z.str.start_with "$name" __z_cls_
}

# Check that an attribute can be restored as an ordinary local parameter.
#
# $1: attribute name
# REPLY: unchanged
# return: 0|1
z.cls.is.attribute() {
  z.cls.is.name "${1:-}" &&
    z.is.not.eq "$1" REPLY &&
    z.is.not.eq "$1" reply &&
    z.str.excludes "${parameters[$1]:-}" special
}
