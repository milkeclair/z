# check if commit args are enough to create a commit
# if not, show help
#
# $@: commit args
# REPLY: null
# return: 0|1
#
# example:
#   z.git.commit.arg.is.enough -m "commit message" #=> true
#   z.git.commit.arg.is.enough #=> false
z.git.commit.arg.is.enough() {
  local tag_and_message=2

  z.arr.count $@
  if z.int.is.lt $REPLY $tag_and_message; then
    z.io.line
    z.git.commit.help
    return 1
  fi
}
