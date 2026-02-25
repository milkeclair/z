z.git.stats.commit.count() {
  local author=$1

  # wc -l: count lines
  command git log --oneline --author=$author |
    command grep -v "Merge branch\|Merge pull request" | \
    command wc -l
}
