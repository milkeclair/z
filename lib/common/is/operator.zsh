for not_file in ${z_root}/lib/common/is/not/*.zsh; do
  source ${not_file}
done

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
#  z.is.truthy "true" #=> 0
#  z.is.truthy 0 #=> 0
#  z.is.truthy "/path/to/existing/dir" #=> 0
#  z.is.truthy "/path/to/existing/file" #=> 0
#  z.is.truthy "some string" #=> 0
#
#  z.is.truthy #=> 1
#  z.is.truthy "" #=> 1
#  z.is.truthy "false" #=> 1
#  z.is.truthy 1 #=> 1
#  z.is.truthy "/path/to/non-existing/dir" #=> 1
#  z.is.truthy "/path/to/non-existing/file" #=> 1
z.is.truthy() {
  local value=$1

  z.guard; {
    z.arg.is.empty $@ && return 1
    z.is.false $value && return 1
  }

  z.is.true $value && return 0
  z.dir.exists $value && return 0
  z.file.exists $value && return 0
  z.str.is.path_like $value && return 1

  z.is.not.null $value && return 0

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
#  z.is.falsy #=> 0
#  z.is.falsy "false" #=> 0
#  z.is.falsy 1 #=> 0
#  z.is.falsy "" #=> 0
#  z.is.falsy "/path/to/non-existing/dir" #=> 0
#  z.is.falsy "/path/to/non-existing/file" #=> 0
#
#  z.is.falsy "true" #=> 1
#  z.is.falsy 0 #=> 1
#  z.is.falsy "some string" #=> 1
#  z.is.falsy "/path/to/existing/dir" #=> 1
#  z.is.falsy "/path/to/existing/file" #=> 1
z.is.falsy() {
  local value=$1

  z.guard; {
    z.arg.is.empty $@ && return 0
    z.is.true $value && return 1
  }

  z.is.false $value && return 0
  z.is.null $value && return 0

  z.str.is.path_like $value &&
  z.dir.not.exists $value &&
  z.file.not.exists $value &&
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
#  z.is.true true #=> 0
#  z.is.true 0 #=> 0
#
#  z.is.true false #=> 1
#  z.is.true 1 #=> 1
#  z.is.true "some string" #=> 1
#  z.is.true "" #=> 1
z.is.true() {
  local value=$1

  z.is.eq $value true && return 0
  z.is.eq $value 0 && return 0

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
#  z.is.false false #=> 0
#  z.is.false 1 #=> 0
#
#  z.is.false true #=> 1
#  z.is.false 0 #=> 1
#  z.is.false "some string" #=> 1
#  z.is.false "" #=> 1
z.is.false() {
  local value=$1

  z.is.eq $value false && return 0
  z.is.eq $value 1 && return 0

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
#  z.is.eq "a" "a" #=> 0
#  z.is.eq 1 1 #=> 0
#  z.is.eq "" "" #=> 0
z.is.eq() {
  local base=$1
  local other=$2

  [[ $base == $other ]]
}

# verifies whether the provided value is null or not
#
# $1: value
# REPLY: null
# return: 0|1
#
# example:
#  z.is.null "" #=> 0
#  z.is.null #=> 0
z.is.null() {
  local value=$1

  [[ -z $value ]]
}
