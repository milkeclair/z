# check whether a cache source line is a comment line
#
# $1: source line
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.cache.build.line.is._comment "# docs"
z.completion.cache.build.line.is._comment() {
  local line=$1
  z.str.gsub str="$line" search="^[[:space:]]+" replace=""
  local trimmed_line=$REPLY

  z.str.start_with "$trimmed_line" "#"
}
