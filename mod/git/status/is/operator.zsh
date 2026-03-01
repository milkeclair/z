# check if git status is dirty
#
# REPLY: null
# return: 0|1
#
# example:
#  if z.git.status.is.dirty; then
z.git.status.is.dirty() {
  z.is.not.null "$(git status --porcelain)"
}
