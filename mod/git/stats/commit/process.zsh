# process commit stats for a list of authors
#
# $authors: an array of author names
# $exclude_exts?: array of file extensions to exclude (e.g. "md" "txt")
# $exclude_dirs?: array of directories to exclude (e.g. "docs" "tests")
# REPLY: an array of commit map entries (strings in the format "author:details:commit_count")
# return: null
#
# example:
#   z.git.stats.commit.map authors=("Alice" "Bob") exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
#   #=> REPLY=("Alice:1000 500:50" "Bob:800 300:40")
z.git.stats.commit.map() {
  z.arg.named authors $@ && local authors_raw=$REPLY
  z.arg.named exclude_exts $@ && local exclude_exts=($REPLY)
  z.arg.named exclude_dirs $@ && local exclude_dirs=($REPLY)

  local authors=()
  if z.is.not.null "$authors_raw"; then
    z.str.split str="$authors_raw" delimiter=" "
    authors=($REPLY)
  fi

  local commit_map=()

  for author in ${authors[@]}; do
    z.git.stats.commit.details author="$author" exclude_exts=$exclude_exts exclude_dirs=$exclude_dirs
    z.str.split str="$REPLY" delimiter=" "
    local details=($REPLY)
    z.git.stats.commit.count "$author" && local count=$REPLY

    if z.int.is.not.zero $count; then
      local details_str="${details[1]} ${details[2]}"
      commit_map+=("$author:$details_str:$count")
    fi
  done

  z.return ${commit_map[@]} keep_empty=true
}

# sum inserted and deleted lines to get total lines changed
#
# $author: author name
# $exclude_exts?: array of file extensions to exclude (e.g. "md" "txt")
# $exclude_dirs?: array of directories to exclude (e.g. "docs" "tests")
# REPLY: total number of lines changed by the author
# return: null
#
# example:
#   z.git.stats.commit.details author="milkeclair" exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats.commit.details() {
  z.arg.named author $@ && local author=$REPLY
  z.arg.named exclude_exts $@ && local exclude_exts_raw=$REPLY
  z.arg.named exclude_dirs $@ && local exclude_dirs_raw=$REPLY

  z.git.stats.commit.details.excludes exclude_exts=$exclude_exts_raw exclude_dirs=$exclude_dirs_raw
  z.arr.split "$REPLY" && local patterns=($REPLY)
  local exclude_exts_pattern=$patterns[1]
  local exclude_dirs_pattern=$patterns[2]

  local inserted_total=0 && local deleted_total=0
  local log=$(
    git log --pretty=tformat: --numstat --author="$author" |
      grep -v -E "$exclude_exts_pattern|$exclude_dirs_pattern"
  )

  while read -r inserted deleted _file; do
    z.is.null "$inserted" && z.is.null "$deleted" && continue

    z.is.eq "$inserted" "-" && inserted=0
    z.is.eq "$deleted" "-" && deleted=0
    inserted_total=$((inserted_total + inserted))
    deleted_total=$((deleted_total + deleted))
  done <<< "$log"

  z.return "$inserted_total $deleted_total"
}

# count the number of lines changed
#
# $inserted: number of lines inserted
# $deleted: number of lines deleted
# REPLY: total number of lines changed
# return: null
#
# example:
#   z.git.stats.commit.sum_lines inserted=1000 deleted=500
#   #=> 1500
z.git.stats.commit.sum_lines() {
  z.arg.named inserted $@ && local inserted=$REPLY
  z.arg.named deleted $@ && local deleted=$REPLY

  z.is.null "$inserted" && inserted=0
  z.is.null "$deleted" && deleted=0
  local result=$((inserted + deleted))

  z.return $result
}
