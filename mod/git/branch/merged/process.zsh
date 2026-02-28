# show merged branches
# default without "main" "master" "develop" "release" and current branch
#
# $exclude_branches?: space-separated branch names to exclude
# REPLY: space-separated merged branches
# return: null
#
# example:
#   z.git.branch.merged
z.git.branch.merged.get() {
  z.git.branch.merged.get.excludes "$@"
  local exclude_branches=($REPLY)

  local result=$(git branch --merged)
  local current=$(git branch --show-current)

  local branches=()
  while IFS= read -r branch; do
    z.git.branch.merged.get.remove_symbols $branch && branch=$REPLY
    z.str.is.empty "$branch" && continue

    z.arr.includes target="$branch" $exclude_branches && continue
    z.is.eq "$branch" "$current" && continue

    branches+=("$branch")
  done <<< "$result"

  z.arr.join "$branches"
}

