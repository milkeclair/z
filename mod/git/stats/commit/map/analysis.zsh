z.git.stats.commit.map.split() {
  z.arg.named entry $@ && local entry=$REPLY
  z.str.split str=$entry delimiter=:
  local parts=($REPLY)

  local author=$parts[1]
  local details=$parts[2]
  local commit_count=$parts[3]

  z.str.split str=$details delimiter=" " && local lines=($REPLY)
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

z.git.stats.commit.map.distinct() {
  local commit_map=($@)
  local filtered_entries=()
  local previous_signature=""

  for entry in ${commit_map[@]}; do
    z.git.stats.commit.map.split entry=$entry
    local commit_count=$REPLY[commit_count]
    local inserted=$REPLY[inserted]
    local deleted=$REPLY[deleted]
    local signature="$commit_count:$inserted:$deleted"

    z.is.eq $signature $previous_signature && continue # duplicate

    previous_signature=$signature
    filtered_entries+=($entry)
  done

  z.return $filtered_entries
}
