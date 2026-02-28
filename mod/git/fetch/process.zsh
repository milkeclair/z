# Fetches all branches and tags from the remote repository, pruning any deleted branches.
#
# REPLY: null
# return: null
#
# example:
#   z.git.fetch
z.git.fetch() {
  git fetch --prune
}
