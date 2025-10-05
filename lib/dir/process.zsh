# create a directory if it does not exist
#
# $1: directory path
# REPLY: null
# return: null
#
# example:
#  z.dir.make "/path/to/dir"
z.dir.make() {
  local dir=$1

  z.dir.is_not $dir && mkdir -p $dir
}

# remove a directory if it exists
#
# $1: directory path
# REPLY: null
# return: null
#
# example:
#  z.dir.remove "/path/to/dir"
z.dir.remove() {
  local dir=$1

  z.dir.is $dir && rm -rf $dir
}
