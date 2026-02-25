# check if string is empty
#
# $1: string
# REPLY: null
# return 0|1
#
# example:
#  z.str.is.empty ""
#  z.str.is.empty "hello"
z.str.is.empty() {
  local value=$1

  [[ -z $value ]]
}

# check if string matches pattern
#
# $1: string
# $2: pattern (glob pattern)
# REPLY: null
# return 0|1
#
# example:
#  z.str.is.match "hello" "h*o"  #=> 0 (true)
#  z.str.is.match "hello" "H*O"  #=> 1 (false, case-sensitive)
z.str.is.match() {
  local string=$1
  local pattern=$2

  [[ $string == ${~pattern} ]]
}

# check if string is path-like
#
# $1: string
# REPLY: null
# return 0|1
#
# example:
#  z.str.is.path_like "/usr/local/bin"  #=> 0 (true)
#  z.str.is.path_like "~/documents"     #=> 0 (true)
#  z.str.is.path_like "./script.sh"     #=> 0 (true)
#  z.str.is.path_like "../config"       #=> 0 (true)
#  z.str.is.path_like "."               #=> 0 (true)
#  z.str.is.path_like ".."              #=> 0 (true)
#  z.str.is.path_like "not/a/path"      #=> 1 (false)
z.str.is.path_like() {
  local value=$1

  z.str.is.match $value "/*" && return 0
  z.str.is.match $value "~*" && return 0
  z.str.is.match $value "./*" && return 0
  z.str.is.match $value "../*" && return 0
  z.is.eq $value "." && return 0
  z.is.eq $value ".." && return 0

  return 1
}
