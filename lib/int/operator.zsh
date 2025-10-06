# check if the value is an integer
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is "123" && z.io "is integer" || z.io "is not integer"
z.int.is() {
  local value=$1

  [[ $value == <-> || $value == -<-> || $value == +<-> ]]
}

# check if the value is not an integer
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is_not "123" && z.io "is not integer" || z.io "is integer"
z.int.is_not() {
  local value=$1

  [[ $value != <-> && $value != -<-> && $value != +<-> ]]
}

# compare two integers
#
# $1: base
# $2: other
# REPLY: null
# return: 0|1
#
# example:
#  z.int.eq 123 123 && z.io "equal" || z.io "not equal"
z.int.eq() {
  local a=$1
  local b=$2

  z.int.is $a || return 1
  z.int.is $b || return 1

  (( a == b ))
}

# compare two integers (not equal)
#
# $1: base
# $2: other
# REPLY: null
# return: 0|1
#
# example:
#  z.int.not_eq 123 456 && z.io "not equal" || z.io "equal"
z.int.not_eq() {
  local a=$1
  local b=$2

  z.int.is $a || return 1
  z.int.is $b || return 1

  (( a != b ))
}

# check if the value is zero
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is_zero 0 && z.io "is zero" || z.io "is not zero"
z.int.is_zero() {
  local value=$1

  z.int.is $value || return 1

  z.eq $value 0
}

# check if the value is not zero
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is_not_zero 123 && z.io "is not zero" || z.io "is zero"
z.int.is_not_zero() {
  local value=$1

  z.int.is $value || return 1

  z.not_eq $value 0
}

# check if the value is positive
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is_positive 123 && z.io "is positive" || z.io "is not positive"
z.int.is_positive() {
  local value=$1

  z.int.is $value || return 1

  z.int.gt $value 0
}

# check if the value is negative
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.int.is_negative -123 && z.io "is negative" || z.io "is not negative"
z.int.is_negative() {
  local value=$1

  z.int.is $value || return 1

  z.int.lt $value 0
}

# compare two integers (greater than)
#
# $1: base
# $2: other
# REPLY: null
# return: 0|1
#
# example:
#  z.int.gt 456 123 && z.io "greater" || z.io "not greater"
z.int.gt() {
  local a=$1
  local b=$2

  z.int.is $a || return 1
  z.int.is $b || return 1

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
#  z.int.gteq 456 123 && z.io "greater or equal" || z.io "not greater or equal"
z.int.gteq() {
  local a=$1
  local b=$2

  z.int.is $a || return 1
  z.int.is $b || return 1

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
#  z.int.lt 123 456 && z.io "less" || z.io "not less"
z.int.lt() {
  local a=$1
  local b=$2

  z.int.is $a || return 1
  z.int.is $b || return 1

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
#  z.int.lteq 123 456 && z.io "less or equal" || z.io "not less or equal"
z.int.lteq() {
  local a=$1
  local b=$2

  z.int.is $a || return 1
  z.int.is $b || return 1

  (( a <= b ))
}
