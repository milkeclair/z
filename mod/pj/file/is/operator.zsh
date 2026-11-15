# check whether a registry entry is a plain file rather than a symbolic link
#
# $1: registration file path
# REPLY: null
# return: 0|1
#
# example:
#  z.pj.file.is.registration /tmp/config/z/pj/example
z.pj.file.is.registration() {
  z.file.exists "$1" && [[ ! -L $1 ]]
}
