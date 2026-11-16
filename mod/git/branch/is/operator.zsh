# ブランチが存在するか確認する
#
# $1: ブランチ名
# REPLY: null
# return: 0|1
#
# example:
#  # feature-branchが存在するリポジトリの場合
#  z.git.branch.is.exists feature-branch
#  # return: 0
z.git.branch.is.exists() {
  local branch=$1

  git show-ref --verify --quiet "refs/heads/$branch"
}
