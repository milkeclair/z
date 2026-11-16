# ブランチが存在するか確認する
#
# $1: ブランチ名
# REPLY: null
# return: 0|1
#
# example:
#  # feature-branchが存在しないリポジトリの場合
#  z.git.branch.is.not.exists feature-branch
#  # return: 0
z.git.branch.is.not.exists() {
  ! z.git.branch.is.exists $1
}
