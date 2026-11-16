# コミット統計の見出しを表示する
#
# REPLY: null
# return: null
#
# example:
#   z.git.stats._author.header #=> display header for commit stats table
z.git.stats._author.header() {
  # 22, 12, 12, 12, 12
  z.io "┌──────────────────────┬────────────┬────────────┬────────────┬────────────┐"
  z.io "│ author               │ commit     │ add        │ delete     │ total      │"
  z.io "├──────────────────────┼────────────┼────────────┼────────────┼────────────┤"
}

# 作成者ごとのコミット統計を表形式で表示する
#
# $exclude_exts?: 除外する拡張子の配列（例: "md" "txt"）
# $exclude_dirs?: 除外するディレクトリの配列（例: "docs" "tests"）
# REPLY: null
# return: null
#
# example:
#   z.git.stats._author.body exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats._author.body() {
  z.arg.named exclude_exts $@ && local exclude_exts=($REPLY)
  z.arg.named exclude_dirs $@ && local exclude_dirs=($REPLY)
  z.git.stats._author.names && local authors=($REPLY)

  local commit_map=()
  z.git.stats._commit.map authors="${authors[*]}" exclude_exts="${exclude_exts[*]}" exclude_dirs="${exclude_dirs[*]}"
  z.git.stats._commit.map.distinct "${REPLY[@]}" && commit_map=("${REPLY[@]}")

  for entry in "${commit_map[@]}"; do
    z.git.stats._commit.map.split entry="$entry"
    local -A parsed=($REPLY)
    local author=$parsed[author]
    local commit_count=$parsed[commit_count]
    local inserted=$parsed[inserted]
    local deleted=$parsed[deleted]
    local total=$parsed[total]

    # 例: author_name commit: 100 add: 1000 delete: 1000 total: 2000
    z.git.stats._author.show \
      author="$author" \
      commit_count="$commit_count" \
      inserted="$inserted" \
      deleted="$deleted" \
      total="$total"

    if z.is.not.eq "$entry" "${commit_map[-1]}"; then
      z.git.stats._author.border
    fi
  done
}

# 作成者の統計を表の1行として表示する
#
# $author: 作成者名
# $commit_count: 作成者のコミット数
# $inserted: 作成者の追加行数
# $deleted: 作成者の削除行数
# $total: 作成者の変更行数の合計
#
# REPLY: null
# return: null
#
# example:
#   z.git.stats._author.show author="milkeclair" commit_count=100 inserted=1000 deleted=1000 total=2000
#   #=> display a table row for milkeclair with her commit stats
z.git.stats._author.show() {
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

  # %-20s: 文字列を幅20で左寄せする
  # %-10d: 数字を幅10で左寄せする
  # 例: │ author_name │ commit: 100 │ add: 1000 │ delete: 1000 │ total: 2000 │
  printf "│ %-20s │ ${yellow}%-10d${reset} │ ${green}%-10d${reset} │ ${red}%-10d${reset} │ ${magenta}%-10d${reset} │\n" "$author" "$commit_count" "$inserted" "$deleted" "$total"
}

# コミット統計の表の罫線を表示する
#
# REPLY: null
# return: null
#
# example:
#   z.git.stats._author.border #=> display border for commit stats table
z.git.stats._author.border() {
  # 22, 12, 12, 12, 12
  z.io "├──────────────────────┼────────────┼────────────┼────────────┼────────────┤"
}

# コミット統計の表の末尾を表示する
#
# REPLY: null
# return: null
#
# example:
#   z.git.stats._author.footer #=> display footer for commit stats table
z.git.stats._author.footer() {
  # 22, 12, 12, 12, 12
  z.io "└──────────────────────┴────────────┴────────────┴────────────┴────────────┘"
}
