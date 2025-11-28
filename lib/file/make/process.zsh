# create a file if it does not exist, along with its parent directories
#
# $path: file path
# REPLY: null
# return: null
#
# example:
#  z.file.make.with_dir path="/path/to/file.txt"
z.file.make.with_dir() {
  z.arg.named path $@ && local file=$REPLY

  z.dir.make path=$(dirname $file)
  z.file.make path=$file
}
