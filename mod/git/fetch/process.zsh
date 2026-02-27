# Fetches all branches and tags from the remote repository, pruning any deleted branches.
#
# REPLY: null
# return: null
#
# example:
#   z.git.fetch #=> Fetched all branches and tags from remote.
z.git.fetch() {
  command git fetch --prune
  command echo "Fetched all branches and tags from remote."
}
