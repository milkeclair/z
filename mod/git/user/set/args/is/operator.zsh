# check if the required arguments for setting git user config are provided
#
# $1: user.name value
# $2: user.email value
# REPLY: null
# return: 0|1
#
# example:
#   z.git.user.set.arg.is.enough "milkeclair" "milkeclair@example.com" #=> 0 (valid)
#   z.git.user.set.arg.is.enough "" "milkeclair@example.com" #=> 1 (invalid)
#   z.git.user.set.arg.is.enough "milkeclair" "" #=> 1 (invalid)
z.git.user.set.arg.is.enough() {
  if z.is.null $1 && z.is.null $2; then
    z.io "require user.name"
    z.io "require user.email"
    return 1
  elif z.is.null $1; then
    z.io "require user.name"
    return 1
  elif z.is.null $2; then
    z.io "require user.email"
    return 1
  fi
}
