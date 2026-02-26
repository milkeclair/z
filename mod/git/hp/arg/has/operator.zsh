# check if arguments contain origin
#
# $@: arguments
# REPLY: null
# return: 0|1
#
# example:
#   z.git.hp.arg.has.origin origin develop #=> true
#   z.git.hp.arg.has.origin develop #=> false
z.git.hp.arg.has.origin() {
  for arg in "$@"; do
    if z.is.eq "$arg" "origin"; then
      return 0
    fi
  done
  return 1
}

# check if arguments contain develop or dev
#
# $@: arguments
# REPLY: null
# return: 0|1
#
# example:
#   z.git.hp.arg.has.develop origin develop #=> true
#   z.git.hp.arg.has.develop origin dev #=> true
#   z.git.hp.arg.has.develop origin main #=> false
z.git.hp.arg.has.develop() {
  for arg in "$@"; do
    if z.is.eq "$arg" "dev" || z.is.eq "$arg" "develop"; then
      return 0
    fi
  done
  return 1
}
