# create a file if it does not exist
#
# $1: file path
# REPLY: null
# return: null
#
# example:
#  z.file.make "/path/to/file.txt"
z.file.make() {
  local file=$1

  z.file.is_not $file && touch $file >/dev/null 2>&1
}

# create a file if it does not exist, along with its parent directories
#
# $1: file path
# REPLY: null
# return: null
#
# example:
#  z.file.make_with_dir "/path/to/file.txt"
z.file.make_with_dir() {
  local file=$1

  z.dir.make $(dirname $file)
  z.file.make $file
}
