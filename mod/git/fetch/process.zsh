# リモートから全ブランチとタグを取得し、削除済みのブランチを追跡対象から取り除く。
#
# REPLY: null
# return: null
#
# example:
#   z.git.fetch
z.git.fetch() {
  git fetch --prune
}
