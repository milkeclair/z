# リモートから全ブランチとタグを取得し、削除済みのブランチを追跡対象から取り除く。
#
# REPLY: null
# return: null
#
# example:
#  # originにfeature-branchがあり、取得に成功する場合
#  z.git.fetch
#  # return: 0
#  # 結果: origin/feature-branchがリモート追跡ブランチとして取得される
z.git.fetch() {
  git fetch --prune
}
