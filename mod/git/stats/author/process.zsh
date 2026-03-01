# display commit stats header
#
# REPLY: null
# return: null
#
# example:
#   z.git.stats.author.header #=> display header for commit stats table
z.git.stats.author.header() {
  # 22, 12, 12, 12, 12
  z.io "┌──────────────────────┬────────────┬────────────┬────────────┬────────────┐"
  z.io "│ author               │ commit     │ add        │ delete     │ total      │"
  z.io "├──────────────────────┼────────────┼────────────┼────────────┼────────────┤"
}

# display commit stats for each author in a table format
#
# $exclude_exts: array of file extensions to exclude (e.g. "md" "txt")
# $exclude_dirs: array of directories to exclude (e.g. "docs" "tests")
# REPLY: null
# return: null
#
# example:
#   z.git.stats.author.body exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats.author.body() {
  z.arg.named exclude_exts $@ && local exclude_exts=($REPLY)
  z.arg.named exclude_dirs $@ && local exclude_dirs=($REPLY)
  z.git.stats.author.names && local authors=($REPLY)

  local commit_map=()
  z.git.stats.commit.map authors=$authors exclude_exts=$exclude_exts exclude_dirs=$exclude_dirs
  z.git.stats.commit.map.distinct $REPLY && commit_map=($REPLY) 

  for entry in ${commit_map[@]}; do
    z.git.stats.commit.map.split entry=$entry
    local author=$REPLY[author]
    local commit_count=$REPLY[commit_count]
    local inserted=$REPLY[inserted]
    local deleted=$REPLY[deleted]
    local total=$REPLY[total]

    # e.g. author_name commit: 100 add: 1000 delete: 1000 total: 2000
    z.git.stats.author.show \
      author="$author" \
      commit_count="$commit_count" \
      inserted="$inserted" \
      deleted="$deleted" \
      total="$total"

    if z.is.not.eq $entry ${commit_map[-1]}; then
      z.git.stats.author.border
    fi
  done
}

# display author stats in a table row
#
# $author: author name
# $commit_count: number of commits by the author
# $inserted: number of lines inserted by the author
# $deleted: number of lines deleted by the author
# $total: total number of lines changed by the author
#
# REPLY: null
# return: null
#
# example:
#   z.git.stats.author.show author="milkeclair" commit_count=100 inserted=1000 deleted=1000 total=2000
#   #=> display a table row for milkeclair with her commit stats
z.git.stats.author.show() {
  z.arg.named author $@ && local author=$REPLY
  z.arg.named commit_count $@ && local commit_count=$REPLY
  z.arg.named inserted $@ && local inserted=$REPLY
  z.arg.named deleted $@ && local deleted=$REPLY
  z.arg.named total $@ && local total=$REPLY

  z.is.null $author && author="Everyone"

  z.str.color red && local red=$REPLY
  z.str.color green && local green=$REPLY
  z.str.color yellow && local yellow=$REPLY
  z.str.color magenta && local magenta=$REPLY
  z.str.color reset && local reset=$REPLY

  # %-20s: ljust 20 for string
  # %-10d: ljust 10 for digit
  # example: │ author_name │ commit: 100 │ add: 1000 │ delete: 1000 │ total: 2000 │
  printf "│ %-20s │ ${yellow}%-10d${reset} │ ${green}%-10d${reset} │ ${red}%-10d${reset} │ ${magenta}%-10d${reset} │\n" "$author" "$commit_count" "$inserted" "$deleted" "$total"
}

# display commit stats table border
#
# REPLY: null
# return: null
#
# example:
#   z.git.stats.author.border #=> display border for commit stats table
z.git.stats.author.border() {
  # 22, 12, 12, 12, 12
  z.io "├──────────────────────┼────────────┼────────────┼────────────┼────────────┤"
}

# display commit stats table footer
#
# REPLY: null
# return: null
#
# example:
#   z.git.stats.author.footer #=> display footer for commit stats table
z.git.stats.author.footer() {
  # 22, 12, 12, 12, 12
  z.io "└──────────────────────┴────────────┴────────────┴────────────┴────────────┘"
}
