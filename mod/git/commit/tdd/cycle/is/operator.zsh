# check if commit cycle is valid
#
# $1: commit cycle
# REPLY: null
# return: 0|1
#
# example:
#   z.git.commit.tdd.cycle.is.valid "red" #=> true
#   z.git.commit.tdd.cycle.is.valid "invalid_cycle" #=> false
z.git.commit.tdd.cycle.is.valid() {
  z.git.commit.tdd.cycle.list && local cycle_list=$REPLY
  local cycle=$1

  if z.str.is.not.match " ${cycle_list[*]} " "* $cycle *"; then
    z.io.line
    z.git.commit.help
    return 1
  fi
}
