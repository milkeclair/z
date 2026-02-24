z.git.pull() {
  z.arg.first $@ && local first_arg=$REPLY
  z.is.eq $first_arg "pull" && shift

  if z.git.hp.arg.has.origin "$@"; then
    command git pull "$@"
    return 0
  fi

  if z.git.hp.arg.has.develop "$@"; then
    z.git.pull.develop
    return 0
  fi

  z.git.pull.pr || z.git.pull.current
}

z.git.pull.develop() {
  z.io "Pulling latest changes from develop branch"
  z.io.empty
  command git pull origin develop
}

z.git.pull.pr() {
  z.git.branch.current
  local current_branch=$REPLY

  z.str.match.rest "$current_branch" "pr/"
  local pr_number=$REPLY

  if z.str.is.not.empty "$pr_number" && z.int.is.match "$pr_number"; then
    z.io "Pulling latest changes for PR #${pr_number}"
    z.io.empty
    command git pull origin pull/"$pr_number"/head:"$current_branch"
    return 0
  else
    return 1
  fi
}

z.git.pull.current() {
  z.git.branch.current
  local current_branch=$REPLY

  z.io "Pulling latest changes for current branch $current_branch"
  z.io.empty
  command git pull origin "$current_branch"
}
