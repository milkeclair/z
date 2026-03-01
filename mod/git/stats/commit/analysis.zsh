# count the number of commits for a given author
#
# $1: author name
# REPLY: number of commits by the author
# return: null
#
# example:
#   z.git.stats.commit.count "milkeclair"
z.git.stats.commit.count() {
  local author=$1

  # wc -l: count lines
  local result=$(git log --oneline --author=$author |
    grep -v "Merge branch\|Merge pull request" | \
    wc -l)

  z.return $result
}
