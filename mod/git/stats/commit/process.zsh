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

z.git.stats.commit.sum_lines() {
  z.arg.named inserted $@ && local inserted=$REPLY
  z.arg.named deleted $@ && local deleted=$REPLY

  local result=$(
    command awk -v inserted=$inserted -v deleted=$deleted "BEGIN {print inserted + deleted}"
  )
  z.return $result
}
