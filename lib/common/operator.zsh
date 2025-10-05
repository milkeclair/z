# verifies whether the provided value is truthy or not
# truthy values:
#   - true or 0
#   - non-empty string (that doesn't look like a path)
#   - existing directory path
#   - existing file path
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.is_truthy "true" #=> 0
#  z.is_truthy 0 #=> 0
#  z.is_truthy "/path/to/existing/dir" #=> 0
#  z.is_truthy "/path/to/existing/file" #=> 0
#  z.is_truthy "some string" #=> 0
#
#  z.is_truthy #=> 1
#  z.is_truthy "" #=> 1
#  z.is_truthy "false" #=> 1
#  z.is_truthy 1 #=> 1
#  z.is_truthy "/path/to/non-existing/dir" #=> 1
#  z.is_truthy "/path/to/non-existing/file" #=> 1
z.is_truthy() {
  local value=$1

  z.guard; {
    z.arg.has_not_any $@ && return 1
    z.is_false $value && return 1
  }

  z.is_true $value && return 0
  z.dir.is $value && return 0
  z.file.is $value && return 0
  z.str.is_path_like $value && return 1

  z.is_not_null $value && return 0

  return 1
}

# verifies whether the provided value is falsy or not
# falsy values:
#   - false or 1
#   - null (empty string)
#   - non-existing directory path
#   - non-existing file path
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.is_falsy #=> 0
#  z.is_falsy "false" #=> 0
#  z.is_falsy 1 #=> 0
#  z.is_falsy "" #=> 0
#  z.is_falsy "/path/to/non-existing/dir" #=> 0
#  z.is_falsy "/path/to/non-existing/file" #=> 0
#
#  z.is_falsy "true" #=> 1
#  z.is_falsy 0 #=> 1
#  z.is_falsy "some string" #=> 1
#  z.is_falsy "/path/to/existing/dir" #=> 1
#  z.is_falsy "/path/to/existing/file" #=> 1
z.is_falsy() {
  local value=$1

  z.guard; {
    z.arg.has_not_any $@ && return 0
    z.is_true $value && return 1
  }

  z.is_false $value && return 0
  z.is_null $value && return 0

  z.str.is_path_like $value &&
  z.dir.is_not $value &&
  z.file.is_not $value &&
    return 0

  return 1
}

# verifies whether the provided value is true or not
# true values:
#   - true or 0
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.is_true "true" #=> 0
#  z.is_true 0 #=> 0
#
#  z.is_true "false" #=> 1
#  z.is_true 1 #=> 1
#  z.is_true "some string" #=> 1
#  z.is_true "" #=> 1
z.is_true() {
  local value=$1

  z.eq $value "true" && return 0
  z.eq $value 0 && return 0

  return 1
}

# verifies whether the provided value is false or not
# false values:
#   - false or 1
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.is_false "false" #=> 0
#  z.is_false 1 #=> 0
#
#  z.is_false "true" #=> 1
#  z.is_false 0 #=> 1
#  z.is_false "some string" #=> 1
#  z.is_false "" #=> 1
z.is_false() {
  local value=$1

  z.eq $value "false" && return 0
  z.eq $value 1 && return 0

  return 1
}

# verifies whether the two values are equal
#
# $1: base value
# $2: other value
# REPLY: null
# return: 0|1
#
# example:
#  z.eq "a" "a" #=> 0
#  z.eq 1 1 #=> 0
#  z.eq "" "" #=> 0
z.eq() {
  local base=$1
  local other=$2

  [[ $base == $other ]]

  return $?
}

# verifies whether the two values are not equal
#
# $1: base value
# $2: other value
# REPLY: null
# return: 0|1
#
# example:
#  z.not_eq "a" "b" #=> 0
#  z.not_eq 1 2 #=> 0
#  z.not_eq "" "a" #=> 0
z.not_eq() {
  local base=$1
  local other=$2

  [[ $base != $other ]]

  return $?
}

# verifies whether the provided value is null or not
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.is_null "" #=> 0
#  z.is_null #=> 0
z.is_null() {
  local value=$1

  [[ -z $value ]]

  return $?
}

# verifies whether the provided value is not null
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.is_not_null "a" #=> 0
#  z.is_not_null 0 #=> 0
z.is_not_null() {
  local value=$1

  [[ -n $value ]]

  return $?
}
