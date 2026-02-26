# determine which file extensions and directories to exclude from commit stats analysis
# if not specified, use default values(html, css)
#
# $exclude_exts?: array of file extensions to exclude (e.g. "md" "txt")
# REPLY: array of file extensions to exclude
# return: null
#
# example:
#   z.git.stats.exclude.exts exclude_exts=("md" "txt") #=> ("md" "txt")
z.git.stats.exclude.exts() {
  z.arg.named exclude_exts $@ && local exts=($REPLY)
  if z.is.null $REPLY; then
    exts=(
      html
      css
    )
  fi

  z.return $exts
}

# determine which directories to exclude from commit stats analysis
# if not specified, use default values(node_modules)
#
# $exclude_dirs?: array of directories to exclude (e.g. "docs" "tests")
# REPLY: array of directories to exclude
# return: null
#
# example:
#   z.git.stats.exclude.dirs exclude_dirs=("docs" "tests") #=> ("docs" "tests")
z.git.stats.exclude.dirs() {
  z.arg.named exclude_dirs $@ && local dirs=($REPLY)
  if z.is.null $REPLY; then
    dirs=(
      node_modules
    )
  fi

  z.return $dirs
}
