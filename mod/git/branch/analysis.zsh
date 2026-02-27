# get current branch name
#
# REPLY: current branch name
# return: null
#
# example:
#   z.git.branch.current #=> "main"
z.git.branch.current() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    z.return $(git branch --show-current)
  else
    z.return
  fi
}

# get merged branches
#
# REPLY: merged branch names (one per line)
# return: null
#
# example:
#   z.git.branch.merged #=> "main\nfeature-branch"
z.git.branch.merged() {
  local result=$(git branch --merged)
  local no_checkout=$(z.io $result | grep -v '^[*+]')
  local trimmed=$(z.io $no_checkout | sed 's/^[[:space:]]*//')

  z.return $trimmed
}
