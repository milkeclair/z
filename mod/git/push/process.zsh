z.git.push() {
  z.arg.first $@ && local first_arg=$REPLY
  z.is.eq $first_arg "push" && shift

  if z.git.hp.arg.has.origin "$@"; then
    command git push "$@"
    return 0
  fi

  z.git.push.pr || z.git.push.current
}

z.git.push.pr() {
  z.git.branch.current
  local current_branch=$REPLY

  z.str.match.rest "$current_branch" "pr/"
  local pr_number=$REPLY

  if z.str.is.not.empty "$pr_number" && z.int.is.match "$pr_number"; then
    z.io "Pushing latest changes for PR #${pr_number}"
    z.io.empty
    command git push origin "HEAD:refs/pull/${pr_number}/head"
    return 0
  else
    return 1
  fi
}

z.git.push.current() {
  z.git.branch.current
  local current_branch=$REPLY

  z.io "Pushing latest changes for current branch $current_branch"
  z.io.empty
  command git push --set-upstream origin "$current_branch"
}
