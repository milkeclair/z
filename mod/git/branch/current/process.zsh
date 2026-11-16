# 現在のブランチ名を取得する
#
# REPLY: 現在のブランチ名
# return: null
#
# example:
#   z.git.branch.current._get #=> "main"
z.git.branch.current._get() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    REPLY=$(git branch --show-current)
  else
    REPLY=""
  fi
}
