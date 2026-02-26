# main entry point for git user command
#
# $@: optional arguments for showing or setting git user info
# REPLY: null
# return: null
#
# example:
#   z.git.user #=> shows local and global user info
#   z.git.user --set "Alice" "alice@example.com" #=> sets local user.name and user.email
z.git.user() {
  z.arg.first $@ && local first_arg=$REPLY
  z.is.eq $first_arg "user" && shift

  if z.git.user.opt.is.set "$1"; then
    z.git.user.set "$2" "$3"
  else
    z.git.user.show
  fi
}

# show local and global git user info
#
# REPLY: null
# return: null
#
# example:
#   z.git.user.show
#   #=> user.name: Alice
#   #   user.email: alice@example.com
z.git.user.show() {
  z.git.user.show.info.local
  z.io.line
  z.git.user.show.info.global
}

# set local git user info (name and email)
#
# $1: user.name value
# $2: user.email value
# REPLY: null
# return: 0|1
#
# example:
#   z.git.user.set "Alice" "alice@example.com"
z.git.user.set() {
  z.io "--- set local user info ---"
  z.git.user.set.required "$1" "$2" || return 1

  command git config --local user.name "$1"
  command git config --local user.email "$2"
  z.io "set user.name: $1"
  z.io "set user.email: $2"
}
