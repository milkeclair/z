# check whether a cache source line is a comment line
#
# $1: source line
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.cache.build.line.is._comment "# docs"
z.completion.cache.build.line.is._comment() {
  setopt local_options EXTENDED_GLOB

  local line=$1
  local trimmed_line=${line##[[:space:]]##}
  [[ "$trimmed_line" == \#* ]]
}
