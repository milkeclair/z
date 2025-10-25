# output green dot for successful test
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.success
z.t._log.dot.success() {
  z.t._log.dot.output "."
}

# output red dot for failed test
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.failure
z.t._log.dot.failure() {
  z.t._log.dot.output "F"
}

# output yellow dot for pending test
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.pending
z.t._log.dot.pending() {
  z.t._log.dot.output "*"
}

# internal: output colored dot with line wrapping
#
# $1: dot character (. F *)
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.output "F"
z.t._log.dot.output() {
  local char=$1
  local count_file="${Z_TEST_COMPACT_DIR}/.dot_count"
  local count=0

  z.file.is $count_file && count=$(cat $count_file)

  local terminal_width=${COLUMNS:-80}
  local width=80
  z.int.lt $terminal_width 80 && width=$terminal_width

  if z.int.eq $((count % width)) 0 && z.int.gt $count 0; then
    z.io.line
  fi

  case $char in
    "F") z.str.color.red $char ;;
    "*") z.str.color.yellow $char ;;
    *) z.str.color.green $char ;;
  esac

  printf "%s" $REPLY
  echo $((count + 1)) > $count_file
}
