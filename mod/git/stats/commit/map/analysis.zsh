# コミット情報のエントリを構成要素に分割する
#
# $entry: "author:details:commit_count"形式の文字列
# REPLY: "author"、"commit_count"、"inserted"、"deleted"、"total"をキーとする連想配列
# return: null
#
# example:
#   z.git.stats._commit.map.split entry="milkeclair:1000 500:50"
z.git.stats._commit.map.split() {
  z.arg.named entry "$@" && local entry=$REPLY
  z.str.split str="$entry" delimiter=:
  local parts=($REPLY)

  local author=$parts[1]
  local details=$parts[2]
  local commit_count=$parts[3]

  z.str.split str="$details" delimiter=" " && local lines=($REPLY)
  local inserted=$lines[1]
  local deleted=$lines[2]
  z.git.stats._commit.sum_lines inserted=$inserted deleted=$deleted
  local total=$REPLY

  local -A result=(
    [author]=$author
    [commit_count]=$commit_count
    [inserted]=$inserted
    [deleted]=$deleted
    [total]=$total
  )
  z.hash.entries result
}

# コミット情報の重複するエントリを取り除く
# コミット数・追加行数・削除行数を基にする
#
# $@: コミット情報の配列（各要素は"author:details:commit_count"形式）
# REPLY: 重複を除いたコミット情報の配列
# return: null
#
# example:
#   z.git.stats._commit.map.distinct commit_map=("Alice:1000 500:50" "Bob:800 300:40" "Alice:1000 500:50")
#   #=> REPLY=("Alice:1000 500:50" "Bob:800 300:40")
z.git.stats._commit.map.distinct() {
  local commit_map=("$@")
  local filtered_entries=()
  local -A seen_signatures=()

  for entry in "${commit_map[@]}"; do
    z.git.stats._commit.map.split entry="$entry"
    local -A parsed=($REPLY)
    local commit_count=$parsed[commit_count]
    local inserted=$parsed[inserted]
    local deleted=$parsed[deleted]
    local signature="$commit_count:$inserted:$deleted"

    z.is.true "$seen_signatures[$signature]" && continue

    seen_signatures[$signature]=true
    filtered_entries+=("$entry")
  done

  REPLY=("${filtered_entries[@]}")
}
