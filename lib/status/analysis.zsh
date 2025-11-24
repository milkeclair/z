# get exit status of last command
#
# REPLY: exit status of last command
# return: null
#
# example:
#  z.status #=> returns the exit status of the last command
z.status() {
  z.return $?
}
