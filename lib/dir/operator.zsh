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

# check if a directory does not exist
#
# $1: directory path
# REPLY: null
# return: 0|1
#
# example:
#  z.dir.not_exists "/path/to/dir" #=> return 0 if not exists
z.dir.not_exists() {
  local dir=$1

  ! z.dir.exists $dir
}
