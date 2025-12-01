# compare exit status
#
# REPLY: null
# return: 0|1
#
# example:
#  z.status.is.true #=> returns true if the last command exited with status 0
z.status.is.true() {
  z.status
  z.is.true $REPLY
}

# compare exit status
#
# REPLY: null
# return: 0|1
#
# example:
#  z.status.is.false #=> returns true if the last command exited with non-zero status
z.status.is.false() {
  z.status
  z.is.false $REPLY
}
