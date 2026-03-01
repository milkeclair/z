# format exclude patterns
#
# $exclude_exts?: array of file extensions to exclude (e.g. "md" "txt")
# $exclude_dirs?: array of directories to exclude (e.g. "docs" "tests")
# REPLY: a string containing the exclude patterns for file extensions and directories
# return: null
#
# example:
#   z.git.stats.commit.details.excludes exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
#   #=> REPLY="\.(md|txt)$ (docs|tests)/"
z.git.stats.commit.details.excludes() {
  z.arg.named exclude_exts $@ && local exclude_exts_raw=$REPLY
  z.arg.named exclude_dirs $@ && local exclude_dirs_raw=$REPLY

  if z.is.not.null "$exclude_exts_raw"; then
    z.str.split str="$exclude_exts_raw" delimiter=" "
    local exclude_exts=($REPLY)
  fi

  if z.is.not.null "$exclude_dirs_raw"; then
    z.str.split str="$exclude_dirs_raw" delimiter=" "
    local exclude_dirs=($REPLY)
  fi

  z.arr.join $exclude_exts delimiter="|" && exclude_exts=$REPLY
  z.arr.join $exclude_dirs delimiter="|" && exclude_dirs=$REPLY

  # e.g. \.(html|css)$
  local exclude_exts_pattern="\.($exclude_exts)$"
  # e.g. /(node_modules|dist)/
  local exclude_dirs_pattern="($exclude_dirs)/"

  z.return "$exclude_exts_pattern $exclude_dirs_pattern"
}
