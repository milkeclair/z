for map_file in ${z_root}/mod/git/stats/commit/map/*.zsh; do
  source $map_file
done

z.git.stats.commit.count() {
  local author=$1

  # wc -l: count lines
  command git log --oneline --author=$author |
    command grep -v "Merge branch\|Merge pull request" | \
    command wc -l
}
