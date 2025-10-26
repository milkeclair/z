# check if a file exists
#
# $1: file path
# REPLY: null
# return: 0|1
#
# example:
#  z.file.exist "/path/to/file" #=> 0
z.file.exist() {
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
#  z.file.not_exist "/path/to/file" #=> 1
z.file.not_exist() {
  ! z.file.exist $1
}
