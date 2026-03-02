# interactive mode for git
#
# REPLY: null
# return: null
#
# example:
#  z.git.mode
#  $z.git.mode> add file.txt
#  $z.git.mode> c.g feat "add new feature"
z.git.mode() {
  z.mode z.git split=.
}
