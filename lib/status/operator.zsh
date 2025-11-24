# compare exit status
#
# REPLY: null
# return: 0|1
#
# example:
#  z.status.is_true #=> returns true if the last command exited with status 0
z.status.is_true() {
  z.status
  z.is_true $REPLY
}

# compare exit status
#
# REPLY: null
# return: 0|1
#
# example:
#  z.status.is_false #=> returns true if the last command exited with non-zero status
z.status.is_false() {
  z.status
  z.is_false $REPLY
}
