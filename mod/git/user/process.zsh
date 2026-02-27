# display git user info (name and email) for both local and global configurations
#
# REPLY: null
# return: null
#
# example:
#   z.git.user
#   #=> --- local user info ---
#   #   user.name: Alice
#   #   user.email: alice@example.com...
z.git.user() {
  z.git.user.local
  z.io.line
  z.git.user.global
}

# display local git user info (name and email)
#
# REPLY: null
# return: null
#
# example:
#   z.git.user.local
#   #=> user.name: Alice
#   #   user.email: alice@example.com
z.git.user.local() {
  z.io "--- local user info ---"
  local_user_name=$(command git config --local user.name)
  local_user_email=$(command git config --local user.email)
  z.io "user.name: $local_user_name"
  z.io "user.email: $local_user_email"
}

# display global git user info (name and email)
#
# REPLY: null
# return: null
#
# example:
#   z.git.user.global
#   #=> user.name: Alice
#   #   user.email: alice@example.com
z.git.user.global() {
  z.io "--- global user info ---"
  global_user_name=$(command git config --global user.name)
  global_user_email=$(command git config --global user.email)
  z.io "user.name: $global_user_name"
  z.io "user.email: $global_user_email"
}
