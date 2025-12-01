# verifies whether the two values are not equal
#
# $1: base value
# $2: other value
# REPLY: null
# return: 0|1
#
# example:
#  z.is.not.eq "a" "b" #=> 0
#  z.is.not.eq 1 2 #=> 0
#  z.is.not.eq "" "a" #=> 0
z.is.not.eq() {
  local base=$1
  local other=$2

  [[ $base != $other ]]
}

# verifies whether the provided value is not null
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.is.not.null "a" #=> 0
#  z.is.not.null 0 #=> 0
z.is.not.null() {
  local value=$1

  [[ -n $value ]]
}
