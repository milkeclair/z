for not_file in ${z_root}/lib/int/is/not/*.zsh; do
  source ${not_file}
done

# check if the value is an integer
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.match "123" && z.io "is integer" || z.io "is not integer"
z.int.is.match() {
  local value=$1

  [[ $value == <-> || $value == -<-> || $value == +<-> ]]
}

# compare two integers
#
# $1: base
# $2: other
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.eq 123 123 && z.io "equal" || z.io "not equal"
z.int.is.eq() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a == b ))
}

# check if the value is zero
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.zero 0 && z.io "is zero" || z.io "is not zero"
z.int.is.zero() {
  local value=$1

  z.int.is.match $value || return 1

  z.is.eq $value 0
}

# check if the value is positive
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.positive 123 && z.io "is positive" || z.io "is not positive"
z.int.is.positive() {
  local value=$1

  z.int.is.match $value || return 1

  z.int.is.gt $value 0
}

# check if the value is negative
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.negative -123 && z.io "is negative" || z.io "is not negative"
z.int.is.negative() {
  local value=$1

  z.int.is.match $value || return 1

  z.int.is.lt $value 0
}

# compare two integers (greater than)
#
# $1: base
# $2: other
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.gt 456 123 && z.io "greater" || z.io "not greater"
z.int.is.gt() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a > b ))
}

# compare two integers (greater than or equal)
#
# $1: base
# $2: other
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.gteq 456 123 && z.io "greater or equal" || z.io "not greater or equal"
z.int.is.gteq() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a >= b ))
}

# compare two integers (less than)
#
# $1: base
# $2: other
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.lt 123 456 && z.io "less" || z.io "not less"
z.int.is.lt() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a < b ))
}

# compare two integers (less than or equal)
#
# $1: base
# $2: other
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is.lteq 123 456 && z.io "less or equal" || z.io "not less or equal"
z.int.is.lteq() {
  local a=$1
  local b=$2

  z.int.is.match $a || return 1
  z.int.is.match $b || return 1

  (( a <= b ))
}
