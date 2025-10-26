# check if a directory exists
#
# $1: directory path
# REPLY: null
# return: 0|1
#
# example:
#  z.dir.exist "/path/to/dir" #=> return 0 if exists
z.dir.exist() {
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
#  z.dir.not_exist "/path/to/dir" #=> return 0 if not exists
z.dir.not_exist() {
  local dir=$1

  ! z.dir.exist $dir
}
