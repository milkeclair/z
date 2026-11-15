# read a named registration input without converting literal values
#
# $1: input name
# $@: named input arguments
# REPLY: literal input value, or empty when absent
# return: 0
#
# example:
#  z.pj.add._value name name=true
z.pj.add._value() {
  local key=$1
  shift
  local argument
  for argument in "$@"; do
    if [[ $argument == "$key="* ]]; then
      REPLY=${argument#*=}
      return 0
    fi
  done
  REPLY=""
}
