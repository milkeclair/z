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
  if z.git._hp.arg.has.origin "$@"; then
    git pull "$@"
    return 0
  fi

  if z.git._hp.arg.has.develop "$@"; then
    z.git.pull._develop
    return 0
  fi

  z.git.pull._pr || z.git.pull._current
}

# pull latest changes for develop branch
#
# REPLY: null
# return: null
#
# example:
#   z.git.pull._develop #=> pull latest changes for develop branch
z.git.pull._develop() {
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
#   z.git.pull._pr #=> pull latest changes for PR #123
z.git.pull._pr() {
  z.git.branch.current._get
  local current_branch=$REPLY

  z.str.match.rest "$current_branch" "pr/"
  local pr_number=$REPLY

  if z.str.is.not.empty "$pr_number" && z.int.is.match "$pr_number"; then
    local head_ref=$(gh pr view "$pr_number" --json headRefName --jq .headRefName)

    if z.str.is.empty "$head_ref"; then
      z.io.error "Could not resolve head branch for PR #${pr_number}"
      return 1
    fi

    z.io "Pulling latest changes for PR #${pr_number}"
    z.io.empty
    git pull origin "$head_ref"
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
#   z.git.pull._current #=> pull latest changes for current branch
z.git.pull._current() {
  z.git.branch.current._get
  local current_branch=$REPLY

  z.io "Pulling latest changes for current branch $current_branch"
  z.io.empty
  git pull origin "$current_branch"
}
