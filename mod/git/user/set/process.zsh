# set git user info (name and email) for local
#
# $1: user.name value
# $2: user.email value
# REPLY: null
# return: null
#
# example:
#   z.git.user.set "milkeclair" "milkeclair@example.com"
z.git.user.set() {
  z.git.user.set.local "$1" "$2"
}

# set git user info (name and email) for local
#
# $1: user.name value
# $2: user.email value
# REPLY: null
# return: null
#
# example:
#   z.git.user.set.local "milkeclair" "milkeclair@example.com"
z.git.user.set.local() {
  z.io "--- set local user info ---"
  z.git.user.set.arg.is.enough "$1" "$2" || return 1

  git config --local user.name "$1"
  git config --local user.email "$2"
  z.io "set user.name: $1"
  z.io "set user.email: $2"
}

# set git user info (name and email) for global
#
# $1: user.name value
# $2: user.email value
# REPLY: null
# return: null
#
# example:
#   z.git.user.set.global "milkeclair" "milkeclair@example.com"
z.git.user.set.global() {
  z.io "--- set global user info ---"
  z.git.user.set.arg.is.enough "$1" "$2" || return 1

  git config --global user.name "$1"
  git config --global user.email "$2"
  z.io "set user.name: $1"
  z.io "set user.email: $2"
}
