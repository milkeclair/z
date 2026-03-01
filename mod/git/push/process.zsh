# push latest changes for current branch
# if current branch is pr/123, push latest changes for that PR
# if arguments contain "origin", push with those arguments
#
# REPLY: null
# return: null
#
# example:
#   z.git.push #=> push latest changes for current branch
z.git.push() {
  if z.git.hp.arg.has.origin "$@"; then
    git push "$@"
    return 0
  fi

  z.git.push.pr || z.git.push.current
}

# push latest changes for PR branch
#
# REPLY: null
# return: null
#
# example:
#   # if current branch is pr/123
#   z.git.push.pr #=> push latest changes for PR #123
z.git.push.pr() {
  z.git.branch.current.get
  local current_branch=$REPLY

  z.str.match.rest "$current_branch" "pr/"
  local pr_number=$REPLY

  if z.str.is.not.empty "$pr_number" && z.int.is.match "$pr_number"; then
    z.io "Pushing latest changes for PR #${pr_number}"
    z.io.empty
    git push origin "HEAD:refs/pull/${pr_number}/head"
    return 0
  else
    return 1
  fi
}

# push latest changes for current branch
#
# REPLY: null
# return: null
#
# example:
#   z.git.push.current #=> push latest changes for current branch
z.git.push.current() {
  z.git.branch.current.get
  local current_branch=$REPLY

  z.io "Pushing latest changes for current branch $current_branch"
  z.io.empty
  git push --set-upstream origin "$current_branch"
}
