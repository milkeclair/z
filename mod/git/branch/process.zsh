# git branchの別名
#
# $@: git branchのオプションと引数
# REPLY: null
# return: null
#
# example:
#   z.git.b -a # show all branches
z.git.b() {
  z.git.branch "$@"
}

# git branch -aの別名
#
# REPLY: null
# return: null
#
# example:
#   z.git.b.a # show all branches
z.git.b.a() {
  z.git.branch.all
}

# git branchの別名
#
# $@: git branchのオプションと引数
# REPLY: null
# return: null
#
# example:
#   z.git.branch -a # show all branches
z.git.branch() {
  git branch "$@"
}

# git branch -aの別名
#
# REPLY: null
# return: null
#
# example:
#   z.git.branch.all # show all branches
z.git.branch.all() {
  z.git.branch -a
}
