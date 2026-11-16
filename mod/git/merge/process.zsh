# 安全性を高めたmerge
#
# $1: 現在のブランチへマージする対象のブランチ
# REPLY: null
# return: null
#
# example:
#  # 作業ツリーがクリーンで、mainのマージに成功する場合
#  z.git.merge main
#  # return: 0
#  # 結果: 現在のブランチへmainの変更が取り込まれる
z.git.merge() {
  local target_branch=$1

  if z.str.is.empty $target_branch; then
    z.io.line
    z.io.error "Target branch is required for merging."
    return 1
  fi

  if z.git.status._is.dirty; then
    z.io.line
    z.io.error "You have uncommitted changes. Please commit or stash them before merging."
    return 1
  fi

  z.git.fetch
  git merge $target_branch
}
