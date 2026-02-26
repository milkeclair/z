# check if the --set option is provided
#
# $1: first argument passed to the command
# REPLY: null
# return: 0|1
#
# example:
#   z.git.user.opt.is.set --set #=> 0 (true)
#   z.git.user.opt.is.set --get #=> 1 (false)
z.git.user.opt.is.set() {
  if z.is.eq "$1" "--set"; then
    return 0
  else
    return 1
  fi
}
