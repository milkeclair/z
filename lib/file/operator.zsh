# check if a file exists
#
# $1: file path
# REPLY: null
# return: 0|1
#
# example:
#  z.file.is "/path/to/file" #=> 0
z.file.is() {
  local file=$1

  [[ -f $file ]]
}

# check if a file does not exist
#
# $1: file path
# REPLY: null
# return: 0|1
#
# example:
#  z.file.is_not "/path/to/file" #=> 1
z.file.is_not() {
  ! z.file.is $1
}
