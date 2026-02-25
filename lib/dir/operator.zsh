# check if a directory exists
#
# $1: directory path
# REPLY: null
# return: 0|1
#
# example:
#  z.dir.exists "/path/to/dir" #=> return 0 if exists
z.dir.exists() {
  local dir=$1

  [[ -d $dir ]]
}
