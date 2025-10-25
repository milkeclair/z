# create a file if it does not exist
#
# $path: file path
# REPLY: null
# return: null
#
# example:
#  z.file.make path="/path/to/file.txt"
z.file.make() {
  z.arg.named path $@ && local file=$REPLY

  z.file.is_not $file && touch $file >/dev/null 2>&1
}

# create a file if it does not exist, along with its parent directories
#
# $path: file path
# REPLY: null
# return: null
#
# example:
#  z.file.make_with_dir path="/path/to/file.txt"
z.file.make_with_dir() {
  z.arg.named path $@ && local file=$REPLY

  z.dir.make path=$(dirname $file)
  z.file.make path=$file
}
