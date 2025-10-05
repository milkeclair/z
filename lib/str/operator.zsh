# check if string is empty
#
# $1: string
# REPLY: null
# return 0|1
#
# example:
#  z.str.is_empty ""
#  z.str.is_empty "hello"
z.str.is_empty() {
  local value=$1

  [[ -z $value ]]
}

# check if string is not empty
#
# $1: string
# REPLY: null
# return 0|1
#
# example:
#  z.str.is_not_empty ""
#  z.str.is_not_empty "hello"
z.str.is_not_empty() {
  local value=$1

  [[ -n $value ]]
}

# check if string matches pattern
#
# $1: string
# $2: pattern (glob pattern)
# REPLY: null
# return 0|1
#
# example:
#  z.str.is_match "hello" "h*o"  #=> 0 (true)
#  z.str.is_match "hello" "H*O"  #=> 1 (false, case-sensitive)
z.str.is_match() {
  local string=$1
  local pattern=$2

  [[ $string == ${~pattern} ]]
}

# check if string does not match pattern
#
# $1: string
# $2: pattern (glob pattern)
# REPLY: null
# return 0|1
#
# example:
#  z.str.is_not_match "hello" "h*o"  #=> 1 (false)
#  z.str.is_not_match "hello" "H*O"  #=> 0 (true, case-sensitive)
z.str.is_not_match() {
  local string=$1
  local pattern=$2

  [[ $string != ${~pattern} ]]
}

# check if string contains substring
#
# $1: string
# $2: substring
# REPLY: null
# return 0|1
#
# example:
#  z.str.is_include "hello world" "lo wo"  #=> 0 (true)
#  z.str.is_include "hello world" "LO WO"  #=> 1 (false, case-sensitive)
z.str.is_include() {
  local string=$1
  local substring=$2

  [[ $string == *$substring* ]]
}

# check if string does not contain substring
#
# $1: string
# $2: substring
# REPLY: null
# return 0|1
#
# example:
#  z.str.is_not_include "hello world" "lo wo"  #=> 1 (false)
#  z.str.is_not_include "hello world" "LO WO"  #=> 0 (true, case-sensitive)
z.str.is_not_include() {
  local string=$1
  local substring=$2

  [[ $string != *$substring* ]]
}

# check if string starts with prefix
#
# $1: string
# $2: prefix
# REPLY: null
# return 0|1
#
# example:
#  z.str.is_start_with "hello world" "hello"  #=> 0 (true)
#  z.str.is_start_with "hello world" "HELLO"  #=> 1 (false, case-sensitive)
z.str.is_start_with() {
  local string=$1
  local prefix=$2

  [[ $string == $prefix* ]]
}

# check if string ends with suffix
#
# $1: string
# $2: suffix
# REPLY: null
# return 0|1
#
# example:
#  z.str.is_end_with "hello world" "world"  #=> 0 (true)
#  z.str.is_end_with "hello world" "WORLD"  #=> 1 (false, case-sensitive)
z.str.is_end_with() {
  local string=$1
  local suffix=$2

  [[ $string == *$suffix ]]
}

# check if string is path-like
#
# $1: string
# REPLY: null
# return 0|1
#
# example:
#  z.str.is_path_like "/usr/local/bin"  #=> 0 (true)
#  z.str.is_path_like "~/documents"     #=> 0 (true)
#  z.str.is_path_like "./script.sh"     #=> 0 (true)
#  z.str.is_path_like "../config"       #=> 0 (true)
#  z.str.is_path_like "not/a/path"      #=> 1 (false)
z.str.is_path_like() {
  local value=$1

  z.str.is_match $value "/*" && return 0
  z.str.is_match $value "~*" && return 0
  z.str.is_match $value "./*" && return 0
  z.str.is_match $value "../*" && return 0

  return 1
}

# check if string is not path-like
#
# $1: string
# REPLY: null
# return 0|1
#
# example:
#  z.str.is_not_path_like "/usr/local/bin"  #=> 1 (false)
#  z.str.is_not_path_like "~/documents"     #=> 1 (false)
#  z.str.is_not_path_like "./script.sh"     #=> 1 (false)
#  z.str.is_not_path_like "../config"       #=> 1 (false)
#  z.str.is_not_path_like "not/a/path"      #=> 0 (true)
z.str.is_not_path_like() {
  local value=$1

  z.str.is_match $value "/*" && return 1
  z.str.is_match $value "~*" && return 1
  z.str.is_match $value "./*" && return 1
  z.str.is_match $value "../*" && return 1

  return 0
}
