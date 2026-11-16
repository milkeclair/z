# ブランチが存在するか確認する
#
# $1: ブランチ名
# REPLY: null
# return: 0|1
#
# example:
#   z.git.branch.is.not.exists "feature-branch"
z.git.branch.is.not.exists() {
  ! z.git.branch.is.exists $1
}
