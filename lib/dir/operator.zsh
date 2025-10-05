# check if a directory exists
#
# $1: directory path
# REPLY: null
# return: 0|1
#
# example:
#  z.dir.is "/path/to/dir" #=> return 0 if exists
z.dir.is() {
  local dir=$1

  [[ -d $dir ]]
}

# check if a directory does not exist
#
# $1: directory path
# REPLY: null
# return: 0|1
#
# example:
#  z.dir.is_not "/path/to/dir" #=> return 0 if not exists
z.dir.is_not() {
  local dir=$1

  ! z.dir.is $dir
}
