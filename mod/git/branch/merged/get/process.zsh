# get exclude branches from arguments or use default ones
#
# $exclude_branches?: space-separated branch names to exclude
# REPLY: array of branch names to exclude
# return: null
#
# example:
#   z.git.branch.merged.get.excludes exclude_branches="main master feature/a"
z.git.branch.merged.get.excludes() {
  local exclude_branches=(main master develop release)

  z.arg.named exclude_branches "$@" && local exclude_arg=$REPLY
  if z.is.not.null "$exclude_arg"; then
    z.arr.split "$exclude_arg"
    exclude_branches=($REPLY)
  fi

  z.return $exclude_branches
}

# remove symbols like "*", "+" from branch name
#
# $@: branch name parts
# REPLY: normalized branch name
# return: null
#
# example:
#   z.git.branch.merged.get.remove_symbols "* feature/branch" #=> "feature/branch"
z.git.branch.merged.get.remove_symbols() {
  z.str.trim "$1" && local trimmed=$REPLY
  if z.str.start_with "$trimmed" "*" || z.str.start_with "$trimmed" "+"; then
    z.arr.split "$trimmed"
    z.return $REPLY[2]
  else
    z.return "$trimmed"
  fi
}
