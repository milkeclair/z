# Fetches all branches and tags from the remote repository, pruning any deleted branches.
#
# REPLY: null
# return: null
#
# example:
#   z.git.fetch #=> Fetched all branches and tags from remote.
z.git.fetch() {
  git fetch --prune
  z.io "Fetched all branches and tags from remote."
}
