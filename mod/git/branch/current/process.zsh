# get current branch name
#
# REPLY: current branch name
# return: null
#
# example:
#   z.git.branch.current._get #=> "main"
z.git.branch.current._get() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    z.return $(git branch --show-current)
  else
    z.return
  fi
}
