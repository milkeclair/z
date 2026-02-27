# list of valid commit cycles
#
# REPLY: array of valid commit cycles
# return: null
#
# example:
#   z.git.commit.tdd.cycle.list #=> ("red" "green")
z.git.commit.tdd.cycle.list() {
  local tdd_cycles=(
    red
    green
  )

  z.return $tdd_cycles
}
