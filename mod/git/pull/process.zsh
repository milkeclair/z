# pull latest changes for current branch
# if current branch is pr/123, pull latest changes for that PR
# if current branch is develop, pull latest changes for develop branch
# if arguments contain "origin", pull with those arguments
#
# REPLY: null
# return: null
#
# example:
#   z.git.pull #=> pull latest changes for current branch
z.git.pull() {
  if z.git.hp.arg.has.origin "$@"; then
    git pull "$@"
    return 0
  fi

  if z.git.hp.arg.has.develop "$@"; then
    z.git.pull.develop
    return 0
  fi

  z.git.pull.pr || z.git.pull.current
}

# pull latest changes for develop branch
#
# REPLY: null
# return: null
#
# example:
#   z.git.pull.develop #=> pull latest changes for develop branch
z.git.pull.develop() {
  z.io "Pulling latest changes from develop branch"
  z.io.empty
  git pull origin develop
}

# pull latest changes for PR branch
#
# REPLY: null
# return: null
#
# example:
#   # if current branch is pr/123
#   z.git.pull.pr #=> pull latest changes for PR #123
z.git.pull.pr() {
  z.git.branch.current
  local current_branch=$REPLY

  z.str.match.rest "$current_branch" "pr/"
  local pr_number=$REPLY

  if z.str.is.not.empty "$pr_number" && z.int.is.match "$pr_number"; then
    z.io "Pulling latest changes for PR #${pr_number}"
    z.io.empty
    git pull origin pull/"$pr_number"/head:"$current_branch"
    return 0
  else
    return 1
  fi
}

# pull latest changes for current branch
#
# REPLY: null
# return: null
#
# example:
#   z.git.pull.current #=> pull latest changes for current branch
z.git.pull.current() {
  z.git.branch.current
  local current_branch=$REPLY

  z.io "Pulling latest changes for current branch $current_branch"
  z.io.empty
  git pull origin "$current_branch"
}
