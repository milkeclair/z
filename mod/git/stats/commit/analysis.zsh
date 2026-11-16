# 指定した作成者のコミット数を数える
#
# $1: 作成者名
# REPLY: 作成者のコミット数
# return: null
#
# example:
#  # milkeclairのマージ以外のコミットが2件ある場合
#  z.git.stats._commit.count milkeclair
#  # REPLY: 2
z.git.stats._commit.count() {
  local author=$1

  # wc -l: 行数を数える
  local result=$(git log --oneline --author="$author" |
    grep -v "Merge branch\|Merge pull request" | \
    wc -l)

  REPLY=$result
}
