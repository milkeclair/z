z.git.branch.is.exists() {
  local branch=$1

  command git show-ref --verify --quiet "refs/heads/$branch"
}
