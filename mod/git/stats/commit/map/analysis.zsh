# split a commit map entry into its components
#
# $entry: a string in the format "author:details:commit_count"
# REPLY: an associative array with keys "author", "commit_count", "inserted", "deleted", "total"
# return: null
#
# example:
#   z.git.stats.commit.map.split entry="milkeclair:1000 500:50"
z.git.stats.commit.map.split() {
  z.arg.named entry "$@" && local entry=$REPLY
  z.str.split str="$entry" delimiter=:
  local parts=($REPLY)

  local author=$parts[1]
  local details=$parts[2]
  local commit_count=$parts[3]

  z.str.split str="$details" delimiter=" " && local lines=($REPLY)
  local inserted=$lines[1]
  local deleted=$lines[2]
  z.git.stats.commit.sum_lines inserted=$inserted deleted=$deleted
  local total=$REPLY

  local -A result=(
    [author]=$author
    [commit_count]=$commit_count
    [inserted]=$inserted
    [deleted]=$deleted
    [total]=$total
  )
  z.return.hash result
}

# remove duplicate entries from a commit map
# based on their commit count, inserted, and deleted lines
#
# $@: an array of commit map entries (strings in the format "author:details:commit_count")
# REPLY: an array of unique commit map entries
# return: null
#
# example:
#   z.git.stats.commit.map.distinct commit_map=("Alice:1000 500:50" "Bob:800 300:40" "Alice:1000 500:50")
#   #=> REPLY=("Alice:1000 500:50" "Bob:800 300:40")
z.git.stats.commit.map.distinct() {
  local commit_map=("$@")
  local filtered_entries=()
  local -A seen_signatures=()

  for entry in "${commit_map[@]}"; do
    z.git.stats.commit.map.split entry="$entry"
    local -A parsed=($REPLY)
    local commit_count=$parsed[commit_count]
    local inserted=$parsed[inserted]
    local deleted=$parsed[deleted]
    local signature="$commit_count:$inserted:$deleted"

    z.is.true "$seen_signatures[$signature]" && continue

    seen_signatures[$signature]=true
    filtered_entries+=("$entry")
  done

  z.return "${filtered_entries[@]}" keep_empty=true
}
