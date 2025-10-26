# create a directory if it does not exist
#
# $path: directory path
# REPLY: null
# return: null
#
# example:
#  z.dir.make path="/path/to/dir"
z.dir.make() {
  z.arg.named path $@ && local dir=$REPLY

  z.dir.not_exist $dir && mkdir -p $dir
}

# remove a directory if it exists
#
# $path: directory path
# REPLY: null
# return: null
#
# example:
#  z.dir.remove path="/path/to/dir"
z.dir.remove() {
  z.arg.named path $@ && local dir=$REPLY

  z.dir.exist $dir && rm -rf $dir
}
