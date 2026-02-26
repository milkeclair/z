# process commit stats for a list of authors
#
# $authors: an array of author names
# $exclude_exts: array of file extensions to exclude (e.g. "md" "txt")
# $exclude_dirs: array of directories to exclude (e.g. "docs" "tests")
# REPLY: an array of commit map entries (strings in the format "author:details:commit_count")
# return: null
#
# example:
#   z.git.stats.commit.map authors=("Alice" "Bob") exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
#   #=> REPLY=("Alice:1000 500:50" "Bob:800 300:40")
z.git.stats.commit.map() {
  z.arg.named authors $@ && local authors=($REPLY)
  z.arg.named exclude_exts $@ && local exclude_exts=($REPLY)
  z.arg.named exclude_dirs $@ && local exclude_dirs=($REPLY)
  local commit_map=()

  for author in ${authors[@]}; do
    z.git.stats.commit.details author=$author exclude_exts=$exclude_exts exclude_dirs=$exclude_dirs
    local details=($REPLY)
    z.git.stats.commit.count $author && local count=$REPLY

    if z.int.is.not.zero $count; then
      commit_map+=($author:$details:$count)
    fi
  done

  z.return $commit_map
}

# sum inserted and deleted lines to get total lines changed
#
# $author: author name
# $exclude_exts: array of file extensions to exclude (e.g. "md" "txt")
# $exclude_dirs: array of directories to exclude (e.g. "docs" "tests")
# REPLY: total number of lines changed by the author
# return: null
#
# example:
#   z.git.stats.commit.details author="Alice" exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats.commit.details() {
  z.arg.named author $@ && local author=$REPLY
  z.arg.named exclude_exts $@ && local exclude_exts=($REPLY)
  z.arg.named exclude_dirs $@ && local exclude_dirs=($REPLY)

  # grep -v -E: exclude files with specific extensions
  # e.g. \.(html|css)$
  local exclude_exts_pattern="\.($(IFS=\|; echo ${exclude_exts[*]}))$"
  # e.g. /(node_modules|dist)/
  local exclude_dirs_pattern="($(IFS=\|; echo ${exclude_dirs[*]}))/"

  local result=$(command git log --pretty=tformat: --numstat --author=$author |
    command grep -v -E "$exclude_exts_pattern|$exclude_dirs_pattern" |
    command awk "{inserted+=$1; deleted+=$2} END {print inserted, deleted}")

  z.return $result
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

  local result=$(
    command awk -v inserted=$inserted -v deleted=$deleted "BEGIN {print inserted + deleted}"
  )

  z.return $result
}
