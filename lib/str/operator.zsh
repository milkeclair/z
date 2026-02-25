# check if string contains substring
#
# $1: string
# $2: substring
# REPLY: null
# return 0|1
#
# example:
#  z.str.includes "hello world" "lo wo"  #=> 0 (true)
#  z.str.includes "hello world" "LO WO"  #=> 1 (false, case-sensitive)
z.str.includes() {
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
#  z.str.excludes "hello world" "lo wo"  #=> 1 (false)
#  z.str.excludes "hello world" "LO WO"  #=> 0 (true, case-sensitive)
z.str.excludes() {
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
#  z.str.start_with "hello world" "hello"  #=> 0 (true)
#  z.str.start_with "hello world" "HELLO"  #=> 1 (false, case-sensitive)
z.str.start_with() {
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
#  z.str.end_with "hello world" "world"  #=> 0 (true)
#  z.str.end_with "hello world" "WORLD"  #=> 1 (false, case-sensitive)
z.str.end_with() {
  local string=$1
  local suffix=$2

  [[ $string == *$suffix ]]
}
