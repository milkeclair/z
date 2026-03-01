# display commit stats for each author
#
# $@: optional arguments for excluding certain file extensions or directories from the analysis
# REPLY: null
# return: null
#
# example:
#   z.git.stats.author exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats() {
  z.io.line
  z.io "--- author stats ---"
  z.git.stats.show "$@"
}

# show commit stats for each author
# excluding specified file extensions and directories
#
# $exclude_exts?: array of file extensions to exclude (e.g. "md" "txt")
# $exclude_dirs?: array of directories to exclude (e.g. "docs" "tests")
# REPLY: null
# return: null
#
# example:
#   z.git.stats.show exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats.show() {
  z.git.stats.exclude.exts $@ && local exclude_exts=($REPLY)
  z.git.stats.exclude.dirs $@ && local exclude_dirs=($REPLY)

  z.git.stats.exclude exclude_exts="${exclude_exts[*]}" exclude_dirs="${exclude_dirs[*]}"
  z.git.stats.author exclude_exts="${exclude_exts[*]}" exclude_dirs="${exclude_dirs[*]}"
}

# display which file extensions and directories are excluded from commit stats analysis
#
# $exclude_exts?: array of file extensions to exclude (e.g. "md" "txt")
# $exclude_dirs?: array of directories to exclude (e.g. "docs" "tests")
# REPLY: null
# return: null
#
# example:
#   z.git.stats.exclude exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats.exclude() {
  z.arg.named exclude_exts $@ && local exclude_exts=($REPLY)
  z.arg.named exclude_dirs $@ && local exclude_dirs=($REPLY)

  z.io.line "exclude_exts: ${exclude_exts[*]}" "exclude_dirs: ${exclude_dirs[*]}"
  z.io.line
}

# display commit stats for each author in a table format
#
# $exclude_exts?: array of file extensions to exclude (e.g. "md" "txt")
# $exclude_dirs?: array of directories to exclude (e.g. "docs" "tests")
# REPLY: null
# return: null
#
# example:
#   z.git.stats.author exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats.author() {
  z.arg.named exclude_exts $@ && local exclude_exts=$REPLY
  z.arg.named exclude_dirs $@ && local exclude_dirs=$REPLY

  z.git.stats.author.header
  z.git.stats.author.body exclude_exts="$exclude_exts" exclude_dirs="$exclude_dirs"
  z.git.stats.author.footer
}
