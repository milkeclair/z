# check if string is not empty
#
# $1: string
# REPLY: null
# return 0|1
#
# example:
#  z.str.is.not.empty ""
#  z.str.is.not.empty "hello"
z.str.is.not.empty() {
  local value=$1

  [[ -n $value ]]
}

# check if string does not match pattern
#
# $1: string
# $2: pattern (glob pattern)
# REPLY: null
# return 0|1
#
# example:
#  z.str.is.not.match "hello" "h*o"  #=> 1 (false)
#  z.str.is.not.match "hello" "H*O"  #=> 0 (true, case-sensitive)
z.str.is.not.match() {
  local string=$1
  local pattern=$2

  [[ $string != ${~pattern} ]]
}

# check if string is not path-like
#
# $1: string
# REPLY: null
# return 0|1
#
# example:
#  z.str.is.not.path_like "/usr/local/bin"  #=> 1 (false)
#  z.str.is.not.path_like "~/documents"     #=> 1 (false)
#  z.str.is.not.path_like "./script.sh"     #=> 1 (false)
#  z.str.is.not.path_like "../config"       #=> 1 (false)
#  z.str.is.not.path_like "."               #=> 1 (false)
#  z.str.is.not.path_like ".."              #=> 1 (false)
#  z.str.is.not.path_like "not/a/path"      #=> 0 (true)
z.str.is.not.path_like() {
  local value=$1

  z.str.is.match $value "/*" && return 1
  z.str.is.match $value "~*" && return 1
  z.str.is.match $value "./*" && return 1
  z.str.is.match $value "../*" && return 1
  z.is.eq $value "." && return 1
  z.is.eq $value ".." && return 1

  return 0
}
