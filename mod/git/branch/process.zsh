# git branchの別名
#
# $@: git branchのオプションと引数
# REPLY: null
# return: null
#
# example:
#  # mainを選択中で、ブランチがmainとfeature-branchだけの場合
#  z.git.b -a
#  # 表示例:
#  #   feature-branch
#  # * main
z.git.b() {
  z.git.branch "$@"
}

# git branch -aの別名
#
# REPLY: null
# return: null
#
# example:
#  # mainを選択中で、ブランチがmainとfeature-branchだけの場合
#  z.git.b.a
#  # 表示例:
#  #   feature-branch
#  # * main
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
#  # mainを選択中で、ブランチがmainとfeature-branchだけの場合
#  z.git.branch -a
#  # 表示例:
#  #   feature-branch
#  # * main
z.git.branch() {
  git branch "$@"
}

# git branch -aの別名
#
# REPLY: null
# return: null
#
# example:
#  # mainを選択中で、ブランチがmainとfeature-branchだけの場合
#  z.git.branch.all
#  # 表示例:
#  #   feature-branch
#  # * main
z.git.branch.all() {
  z.git.branch -a
}
