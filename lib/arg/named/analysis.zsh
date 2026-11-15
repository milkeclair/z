# get a named argument as literal text without boolean or null conversion
#
# $1: argument name
# $@: named arguments
# REPLY: first matching value, or empty when absent
# return: 0
#
# example:
#  z.arg.named.literal name name=true
z.arg.named.literal() {
  local name=$1
  shift 2>/dev/null
  local arg

  for arg in "$@"; do
    if z.str.start_with "$arg" "$name="; then
      REPLY=${arg#*=}
      return 0
    fi
  done

  REPLY=""
}
