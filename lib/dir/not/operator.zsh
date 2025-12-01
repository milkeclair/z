# check if a directory does not exist
#
# $1: directory path
# REPLY: null
# return: 0|1
#
# example:
#  z.dir.not.exists "/path/to/dir" #=> return 0 if not exists
z.dir.not.exists() {
  local dir=$1

  ! z.dir.exists $dir
}
