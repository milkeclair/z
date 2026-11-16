# マージ済みのブランチを表示する
# 既定では"main"、"master"、"develop"、"release"と現在のブランチを除く
#
# $exclude_branches?: 空白区切りの除外ブランチ名
# REPLY: 空白区切りのマージ済みブランチ
# return: null
#
# example:
#   z.git.branch._merged.get
z.git.branch._merged.get() {
  z.git.branch._merged.get.excludes "$@"
  local exclude_branches=($REPLY)

  local result=$(git branch --merged)
  local current=$(git branch --show-current)

  local branches=()
  while IFS= read -r branch; do
    z.git.branch._merged.get.remove_symbols $branch && branch=$REPLY
    z.str.is.empty "$branch" && continue

    z.arr.includes target="$branch" $exclude_branches && continue
    z.is.eq "$branch" "$current" && continue

    branches+=("$branch")
  done <<< "$result"

  z.arr.join "$branches"
}

