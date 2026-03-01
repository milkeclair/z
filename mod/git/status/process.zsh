# show git status with upstream info
#
# REPLY: null
# return: null
#
# example:
#   z.git.status
#   #=> 'origin/main' by 2 commits.
#   #=> M modified_file.txt
z.git.status() {
  local upstream=$(git rev-parse --symbolic-full-name @{u} 2>/dev/null)
  local ahead=$(git rev-list --count "${upstream}..HEAD" 2>/dev/null)

  if z.str.is.not.empty $upstream && z.int.is.not.zero $ahead; then
    z.io "'$upstream' by $ahead commits."
    z.io.line
  fi

	git status --short
}
