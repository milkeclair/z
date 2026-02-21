z.git.commit.tdd.cycle.is.valid() {
  z.git.commit.tdd.cycle.list && local cycle_list=$REPLY
  local cycle=$1

  if z.str.is.not.match " ${cycle_list[*]} " " $cycle "; then
    z.io.line
    z.git.commit.help
    return 1
  fi
}
